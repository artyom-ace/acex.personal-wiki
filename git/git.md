### git clone with ssh-key

- Generate ssh-key ```ssh-keygen```
- check ~/.ssh/id_rsa.pub
- Add ssh-key to github (settings -> ssh and gpg keys -> new ssh key)
- Test ssh connection ```ssh -T git@github.com```
- Clone repository ```git clone git@github.com:artyom-ace/taxi5.driver-rating.git```

### commit and push
```git status```
```git add .```
```git commit -m "message"```
```git push```
