[ -e ~/bin ] && export PATH="$PATH:~/bin"
[ -e ~/.local/bin ] && export PATH="$PATH:~/.local/bin"

[ -e ~/.cargo/bin ] && export PATH="$PATH:~/.cargo/bin"

# required by Dioxus for compiling to Android
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export ANDROID_HOME="$HOME/Android/Sdk"
export NDK_HOME=/opt/android-ndk
[ -d $ANDROID_HOME ] && export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"
