#!/bin/bash
# START === create symlink
export link_path=/opt/csitea/isg-pub/sfw/isg-pub.sh
export target_path=/opt/csitea/isg-pub/isg-pub.1.0.5.prd.ysg/sfw/bash/isg-pub/isg-pub.sh
mkdir -p `dirname $link_path`
unlink $link_path
ln -s "$target_path" "$link_path"
ls -la $link_path;
# STOP === create symlink

