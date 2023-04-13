#!/bin/bash
# Dieses Skript prüft ob alle VM's auf dem Server vernünftig heruntergefahren wurden.
# Fall bei einer VM es nicht funktioniert wird diese ausgeschalted. Nach erfolgreichen beendern der VMs
# fährt der Proxmox Sever herunter

# Gesamtzeit bis ein Stop durchgeführt wird ergibt sich aus
# (Anzahl der Prüfungen) x (Pause zwischen den Prüfungen) = Zeit bis zum stop

# Gesamtzeit bis der Host einfach abgeschaltet wird ergibt sich aus
#((Anzahl der Prüfungen) x (Pause zwischen den Prüfungen))+((Anzahl der force Prüfung) x (Pause zwischen den Prüfungen)) = Zeit bis zum Shutdown

int_proof=10 # Wie oft wird geprüft ob die VM ausgeschalted ist
int_pause=6  # Wieviel Sekunden Pause zwischen den Prüfungen
int_force=10 # Wieviele Versuche bis unabhängig von den VMS der Host abgeschalted wird

# Liste die VM ids auf
list_vm_ids=$(qm list | awk '{print $1}' | tail -n -1)

# führe auf jeder VM einen shutdown befehl aus
for i in ${list_vm_ids} ; do
        echo "Try to shutdown VM $i"
        qm shutdown ${i} &> /dev/null
done

#for ((i=1; i>${int_proof} ; i++) ;do
i=0 ; while true ; do
        i=$[$i+1]                                                       # Zählschleife für die Prüfversuche
        check_state=0                                                   # Status wird in den default gesetzt ob alle VMs gestoppt sind
        sleep ${int_pause}
        echo "Proof number $i"
        for j in ${list_vm_ids} ; do
                vm_state=$(qm status ${j} | awk '{print $2}')           # Prüfe VM Status.
                if [ "$vm_state" = "running"  ] ; then                  # Wenn VM noch läuft und
                        echo "VM $j is running"
                        if [ $i -gt ${int_proof} ] ; then               # wenn die Anzahl der Verusche erreich ist
                                echo "Try to force stop VM $j"          #
                                qm stop ${j} &> /dev/null               # dann stoppe die VM
                        fi                                              # und
                        check_state=1                                   # setze den Satus das eine Vm noch lief
                fi
        done
        if [ ${check_state} = 0 ]; then break ; fi                      # Wenn alle Vms abgeschaltet sind dann beende die Schleife
        if [ $[$i+${int_force}] -eq $[${int_force}+${int_proof}] ]; then break ; fi                     # Wenn die maximalen Versuche erreicht sind beende den Host

done

shutdown -h now
