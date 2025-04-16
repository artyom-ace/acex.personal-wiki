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



### git auth reset
```git push origin 25276```
-> remote: HTTP Basic: Access denied
-> fatal: Authentication failed for 'https://'
#### check user
```git config --global user.name```
-> username
#### check email
```git config --global user.email```
-> email
#### check remote
```git remote -v```
-> origin  https://.git (fetch)
-> origin  https://.git (push)
#### remove credentials
```git credential reject https://gitlab.com```
```rm ~/.git-credentials```
#### try to push again
```git push origin 25276```
-> Username for 'https://':
-> Password for 'https://':
