  #!/usr/bin/env bash
  ##
  # Autor: Thiago Torres Faioli - A.K.A: 0xttfx - thiago@tcpip.net.br
  # Função: reiniciar instância PGSQL usando conta de sistema sem shell
  # válido que numa tentativa de login via ssh, onde a chave pública for
  # validada o comando `systemctl restart ...` é então executado.
  ##
  # Versão: 0.1
  # Data: 10 de Setembro de 2024
  # Licença: SPDX-License-Identifier: BSD-3-Clause
  #####################################################################
  
  # funcao para log
  _log_msg() {
    local msg="$1"
    local tstamp=$(date +"%d-%m-%Y %H:%M:%S")
    echo "[${tstamp}] ${msg}" >> /var/log/sshpamexec.log
  }
  
  # funcão de restart e status do pgsql
  _restartpg (){
    /usr/bin/systemctl restart postgresql@16-main.service
    _log_msg "$(/usr/bin/systemctl status postgresql@16-main.service --no-pager)"
  }
  
  # variável com parser do fingerprint associado ao último login ssh do usuário restartpg 
  fprint="$(cat /var/log/auth.log |grep -iA1 "accepted publickey"|grep -B1 restartpg |grep -oE "SHA.*$"|/usr/bin/tail -n1)"

  # varoável com arquivo temporário criado para armazenar lista de fingerprit
  # do arquivo authorized_keys do usuário restartpg 
  filelfp="$(mktemp /tmp/listakeyfp-XXX)"
  # inserindo lista de fingerprints 
  for pubkey_file in /home/restartpg/.ssh/authorized_keys ; do ssh-keygen -lf "${pubkey_file}" -E sha256 > "${filelfp}"; done
  
  # variárel com parser identificando o fingerprint
  loginfp=$(/usr/bin/grep "${fprint}" "${filelfp}"| /usr/bin/awk '{print $3,$2}')
  
  _usr_parser (){
  if [ "$PAM_USER" = "restartpg" ]; then
    _log_msg "- - - -"
    _log_msg "Usuário $PAM_USER reinicando instância PGSQL"
    _log_msg "Executado por: $loginfp" 
    _log_msg "-"
    _restartpg
  else 
    _log_msg "- - - -"
    _log_msg "Usuário $PAM_USER! Script $0 ignorado."
  fi
  } 
  _usr_parser
  rm -f "$filelfp"
exit 0
