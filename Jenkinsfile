Started by user develop4God

Obtained Jenkinsfile from git https://github.com/develop4God/Devocional_nuevo.git
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins
 in /var/lib/jenkins/workspace/Devocional_nuevo_Android_CI
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Declarative: Checkout SCM)
[Pipeline] checkout
The recommended git tool is: git
No credentials specified
 > git rev-parse --resolve-git-dir /var/lib/jenkins/workspace/Devocional_nuevo_Android_CI/.git # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://github.com/develop4God/Devocional_nuevo.git # timeout=10
Fetching upstream changes from https://github.com/develop4God/Devocional_nuevo.git
 > git --version # timeout=10
 > git --version # 'git version 2.34.1'
 > git fetch --tags --force --progress -- https://github.com/develop4God/Devocional_nuevo.git +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git rev-parse refs/remotes/origin/main^{commit} # timeout=10
Checking out Revision f08c7a99335ba01113ab2c2b56487d215b65759e (refs/remotes/origin/main)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f f08c7a99335ba01113ab2c2b56487d215b65759e # timeout=10
Commit message: "Update Jenkinsfile"
First time build. Skipping changelog.
[Pipeline] }
[Pipeline] // stage
[Pipeline] withEnv
[Pipeline] {
[Pipeline] withEnv
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Declarative: Checkout SCM)
[Pipeline] checkout
The recommended git tool is: git
No credentials specified
 > git rev-parse --resolve-git-dir /var/lib/jenkins/workspace/Devocional_nuevo_Android_CI/.git # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://github.com/develop4God/Devocional_nuevo.git # timeout=10
Fetching upstream changes from https://github.com/develop4God/Devocional_nuevo.git
 > git --version # timeout=10
 > git --version # 'git version 2.34.1'
 > git fetch --tags --force --progress -- https://github.com/develop4God/Devocional_nuevo.git +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git rev-parse refs/remotes/origin/main^{commit} # timeout=10
Checking out Revision f08c7a99335ba01113ab2c2b56487d215b65759e (refs/remotes/origin/main)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f f08c7a99335ba01113ab2c2b56487d215b65759e # timeout=10
Commit message: "Update Jenkinsfile"
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Load Environment Variables)
[Pipeline] script
[Pipeline] {
[Pipeline] readProperties
[Pipeline] sh
+ echo Variables de entorno cargadas (antes de PATH extendido):
Variables de entorno cargadas (antes de PATH extendido):
[Pipeline] sh
+ echo FLUTTER_HOME: /mnt/c/Users/cesar/dev/flutter_windows_3.32.7-stable/flutter
FLUTTER_HOME: /mnt/c/Users/cesar/dev/flutter_windows_3.32.7-stable/flutter
[Pipeline] sh
+ echo ANDROID_SDK_ROOT: /opt/android-sdk
ANDROID_SDK_ROOT: /opt/android-sdk
[Pipeline] sh
+ echo PATH actual: /usr/sbin:/usr/bin:/sbin:/bin
PATH actual: /usr/sbin:/usr/bin:/sbin:/bin
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Check Flutter)
[Pipeline] withEnv
[Pipeline] {
[Pipeline] sh
+ echo PATH dentro de Check Flutter: /opt/android-sdk/platform-tools:/mnt/c/Users/cesar/dev/flutter_windows_3.32.7-stable/flutter/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/build-tools/34.0.0:/usr/sbin:/usr/bin:/sbin:/bin
PATH dentro de Check Flutter: /opt/android-sdk/platform-tools:/mnt/c/Users/cesar/dev/flutter_windows_3.32.7-stable/flutter/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/build-tools/34.0.0:/usr/sbin:/usr/bin:/sbin:/bin
[Pipeline] sh
+ which flutter
/mnt/c/Users/cesar/dev/flutter_windows_3.32.7-stable/flutter/bin/flutter
[Pipeline] sh
+ flutter --version
/usr/bin/env: ‘bash\r’: No such file or directory
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Install Dependencies)
Stage "Install Dependencies" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Run Tests)
Stage "Run Tests" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Check Java Version)
Stage "Check Java Version" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Check JAVA_HOME)
Stage "Check JAVA_HOME" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Build Android Debug APK)
Stage "Build Android Debug APK" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Build Android AAB for Store)
Stage "Build Android AAB for Store" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Declarative: Post Actions)
[Pipeline] echo
Pipeline finalizado.
[Pipeline] echo
¡El pipeline falló! Revisa los logs para depurar el problema.
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
ERROR: script returned exit code 127
Finished: FAILURE
