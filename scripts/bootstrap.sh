#!/bin/sh
user="abuilder"

set -e

echo "Install alpine-sdk"
apk add alpine-sdk lua-aports

id "$user" >/dev/null 2>&1 || {
	echo "Create user $user"
	adduser -S -D -s /bin/ash -G "abuild" -g "aports builder" "$user"
}

mkdir -p /var/cache/distfiles
chgrp abuild /var/cache/distfiles
chmod g+w /var/cache/distfiles

if ! ls /home/"$user"/.abuild/*.pub >/dev/null 2>&1; then
  su "$user" -c "abuild-keygen -a -n"
  cp /home/"$user"/.abuild/*.pub /etc/apk/keys/
fi

su - "$user" <<EOF
mkdir packages
git clone https://github.com/xdom/aports.git
aports/scripts/build.sh
EOF

sed -i -e "1i /home/$user/packages/main/" /etc/apk/repositories
apk update
echo "Done."

