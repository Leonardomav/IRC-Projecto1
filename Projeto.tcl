if {$argc == 4} {
    set cenario [lindex $argv 0]
    set trafego [lindex $argv 1]
    set quebra [lindex $argv 2]
    set velwindow [lindex $argv 3]
    if {$cenario != 1 && $cenario != 2} {
      puts "Cenario invalido"
      exit 1
    }
    if {$trafego != "UDP" && $trafego != "TCP"} {
      puts "Nao e UDP ou TCP"
      exit 1
    }
    if {$velwindow < 1} {
      puts "Velocidade ou Janela invalida"
      exit 1
    }
    if {$quebra != "ON" && $quebra != "OFF"} {
      puts "Quebra invalida"
      exit 1
    }
} else {
    puts "Numero de argumento invalido"
    exit 1
}

set ns [new Simulator]
$ns rtproto LS

#Creates Tr file to analyse simulation data
set nt [open out.tr w]
$ns trace-all $nt

set nf [open sim.nam w]
$ns namtrace-all $nf

$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green

proc fim {} {
  global ns nf nt
  $ns flush-trace
  close $nf
  close $nt
  exec nam sim.nam
  exit 0;
}

#setup dos nós
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]
set n7 [$ns node]

#Ligaçao dos nós
if {$trafego == "UDP"} {
  $ns duplex-link $n0 $n1 $velwindow+Mb 10ms DropTail
} else {
  $ns duplex-link $n0 $n1 10Mb 10ms DropTail
}
$ns duplex-link $n1 $n2 10Mb 10ms DropTail
$ns simplex-link $n4 $n1 10Mb 5ms DropTail
$ns duplex-link $n2 $n3 10Mb 10ms DropTail
$ns duplex-link $n2 $n5 10Mb 10ms DropTail
$ns duplex-link $n3 $n6 10Mb 10ms DropTail
$ns duplex-link $n4 $n5 10Mb 10ms DropTail
$ns duplex-link $n6 $n5 10Mb 10ms DropTail
$ns duplex-link $n5 $n7 10Mb 10ms DropTail

#Posição dos nós
$ns duplex-link-op $n0 $n1 orient right
$ns duplex-link-op $n1 $n2 orient right
$ns simplex-link-op $n4 $n1 orient up
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n2 $n5 orient down
$ns duplex-link-op $n3 $n6 orient down
$ns duplex-link-op $n4 $n5 orient right
$ns duplex-link-op $n6 $n5 orient left
$ns duplex-link-op $n5 $n7 orient down

#Ediçao dos nós
$n0 color blue
$n0 shape hexagon
$n7 color blue
$n7 shape hexagon
$n1 color red
$n1 shape square
$n5 color green
$n5 shape square

#label dos nos
$n0 label "PC A"
$n1 label "PC B"
$n2 label "PC C"
$n3 label "R3"
$n4 label "R4"
$n5 label "PC D"
$n6 label "R6"
$n7 label "PC E"


#Visualizar filas
$ns duplex-link-op $n0 $n1 queuePos 0.5
$ns duplex-link-op $n1 $n2 queuePos 0.5
$ns simplex-link-op $n4 $n1 queuePos 0.5
$ns duplex-link-op $n2 $n3 queuePos 0.5
$ns duplex-link-op $n2 $n5 queuePos 0.5
$ns duplex-link-op $n3 $n6 queuePos 0.5
$ns duplex-link-op $n4 $n5 queuePos 0.5
$ns duplex-link-op $n6 $n5 queuePos 0.5
$ns duplex-link-op $n5 $n7 queuePos 0.5

#limite 
$ns queue-limit $n0 $n1 2098

if {$quebra == "ON"} {
  $ns rtmodel-at 0.75 down $n2 $n5
  $ns rtmodel-at 0.9 up $n2 $n5
}

if {$trafego == "TCP"} {
  # Create a traffic source in node n0 to n7
  set tcp0 [$ns create-connection TCP $n0 TCPSink $n7 1]
  $tcp0 set window_ $velwindow

  #Cria uma fonte de tráfego CBR(bytes) e liga-a ao tcp0
  set cbr0 [new Application/Traffic/CBR]
  $cbr0 set packetSize_ 2097152
  $cbr0 set maxpkts_ 1
  $cbr0 attach-agent $tcp0

  $ns at 0.5 "$cbr0 start"
  $ns at 10 "$cbr0 stop"

  $tcp0 set class_ 1
}
if {$trafego == "UDP"} {
  # Create a traffic source in node n0
  set udpp [new Agent/UDP]
  $ns attach-agent $n0 $udpp

  #Cria uma fonte de tráfego CBR(bytes) e liga-a ao udpP
  set cbr0 [new Application/Traffic/CBR]
  $cbr0 set packetSize_ 2097152
  $cbr0 set maxpkts_ 1
  $cbr0 attach-agent $udpp

  #Cria um agente Null e liga-o ao nó n7
  set nullp [new Agent/Null]
  $ns attach-agent $n7 $nullp

  $ns connect $udpp $nullp

  $ns at 0.5 "$cbr0 start"
  $ns at 10 "$cbr0 stop"

  $udpp set class_ 1
}

if {$cenario == 2} {
  #Cria um agente UDP e liga-o ao nó n1
  set udp0 [new Agent/UDP]
  $ns attach-agent $n1 $udp0

  #Cria um agente UDP e liga-o ao nó n5
  set udp1 [new Agent/UDP]
  $ns attach-agent $n5 $udp1

  #Cria uma fonte de tráfego CBR(bytes) e liga-a ao udp1
  set cbr1 [new Application/Traffic/CBR]
  $cbr1 set rate_ 6000000
  $cbr1 attach-agent $udp0

  #Cria uma fonte de tráfego CBR(bytes) e liga-a ao udp2
  set cbr2 [new Application/Traffic/CBR]
  $cbr2 set rate_ 5000000
  $cbr2 attach-agent $udp1

  #Cria um agente Null e liga-o ao nó n5
  set null0 [new Agent/Null]
  $ns attach-agent $n5 $null0

  #Cria um agente Null e liga-o ao nó n2
  set null1 [new Agent/Null]
  $ns attach-agent $n2 $null1

  $ns connect $udp0 $null0
  $ns connect $udp1 $null1

  $udp0 set class_ 2
  $udp1 set class_ 3

  $ns at 0.5 "$cbr1 start"
  $ns at 0.5 "$cbr2 start"
  $ns at 10 "$cbr1 stop"
  $ns at 10 "$cbr2 stop"
}

$ns at 10 "fim"

$ns run