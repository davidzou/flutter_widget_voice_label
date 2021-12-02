#!/usr/bin/env bash

##
## 上传应用到pub.dev
## [功能]
##        1. 通过此命令自动增量变化版本号更新，每次+1
##        2. 通过此命令自动增加CHANGELOG的版本信息更新内容，变更内容需手动变更，后续改为提示输入。
##        3. 通过此命令自动变更README对版本号状态图标的更新。
##
## [注意] 这条命令适用Mac系统; Linux暂未测试。其中包含了sed命令的特殊处理。
##
## 检测是否配置了本地配置，中国镜像是不能上传的。
## PUB_HOSTED_URL=https://pub.flutter-io.cn
##

##
## 获取版本号信息
##
function getVersion() {
  #[Major_Version_Number][Minor_Version_Number][Revision_Number][Build_Number]
  if [ -z "$1" ] ; then
    echo "未获取到版本号。"
    exit 0;
  fi
  Major=$(echo "$1" | cut -d '.' -f1)
  Minor=$(echo "$1" | cut -d '.' -f2)
  Revision=$(echo "$1" | cut -d '.' -f3)
  CURRENT_VERSION="$Major.$Minor.$((Revision + 1))"
  # 情况1 Revision号每次增加1，一直增加到99, 100的时候归0，Minor增加1，同样以此类推
  # 情况2 存在buildNumber，即开发版本，测试版本号的判断增加。
}

##
##  更新版本号
##  $1  查找的版本号  $ROLLBACK_VERSION
##  $2  替换的版本号  $CURRENT_VERSION
##
function updateVersion() {
  sed -ig "s/^version: $1/version: $2/g" pubspec.yaml
  ## [*]　添加自定义替换
  sed -ig "s/$1/$2/g" README.md
  sed -ig "s/$1/$2/g" README_zh.md

  ## [*] 删除替换临时文件
  rm pubspec.yamlg
  rm README.mdg
  rm README_zh.mdg
}

## Step 1
## 获取当前版本号     pubspec.yaml 中第三行 version: 0.0.6
CURRENT_VERSION=$(cat pubspec.yaml | grep version: | cut -d ':' -f2 | sed s/[[:space:]]//g)
## 用于失败时回滚的版本好
ROLLBACK_VERSION=$CURRENT_VERSION

## Step 2
## 更新当前小版本号
getVersion "$CURRENT_VERSION"

## 指定版本的操作
if [[ -n $1 ]] ; then
  echo "This is a special version $1"
  CURRENT_VERSION=$1
fi

echo "Current version(Updated): $CURRENT_VERSION"
echo "Rollback version(Before): $ROLLBACK_VERSION"

## Step 3
## 变更版本号
updateVersion "$ROLLBACK_VERSION" "$CURRENT_VERSION"

## Step 4
## 添加ChangeLog描述，提示描述
## 这里mac比较奇葩, 换行使用'\\' 不能使用'\n'
sed -ig "2a\\
\\
\#\# [$CURRENT_VERSION]\\
\\
* 更新内容描述\\
\\ " CHANGELOG.md
rm CHANGELOG.mdg

## Step 5
## 执行dry-run, 检测代码错误。
echo "Execute command -- 'flutter pub publish --dry-run'"
if [[ ! $(flutter pub publish --dry-run) ]] ; then
  echo "With error"
  exit 0
fi

## Step 6
## 检查推送地址
if [ -n "$PUB_HOSTED_URL" ] ; then
  echo "$PUB_HOSTED_URL"
  # 临时变更为pub.dev, 无论设置的是什么。
  eval "export PUB_HOSTED_URL=https://pub.dev"
fi

## Step 7
## 执行上传，错误需要混滚版本号。
echo "是否继续上传到正式服务器？请仔细查看--dry-run的结果。[y/n]"
read -r result
if [[ "$result" == 'y' ]] ; then
  ##  TODO 正式变更CHANGELOG内容

  ## 翻墙代理
  export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7891

  ## FIXME 这里没有考虑到私库，即publish_to不为空的情形。默认提交到pub.dev
  flutter pub publish -v
else
  # 回滚 CHANGELOG
  git checkout CHANGELOG.md
  # 回滚版本号
  updateVersion "$CURRENT_VERSION" "$ROLLBACK_VERSION"
fi