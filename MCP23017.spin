{{
  HAL for the MCP23017 I2C IO expander.

  This code was written by Erik Johnson (originally for UMSAE - Formula Electric)
}}

CON
  #0,OUTPUT,INPUT
  #0,LOW,HIGH
  
  IODIRA   = $00
  IODIRB   = $01 
  IPOLA    = $02 
  IPOLB    = $03 
  GPINTENA = $04 
  GPINTENB = $05 
  DEFVALA  = $06 
  DEFVALB  = $07 
  INTCONA  = $08 
  INTCONB  = $09 
  IOCON    = $0A 
  GPPUA    = $0C 
  GPPUB    = $0D 
  INTFA    = $0E 
  INTFB    = $0F 
  INTCAPA  = $10 
  INTCAPB  = $11 
  GPIOA    = $12 
  GPIOB    = $13 
  OLATA    = $14
  OLATB    = $15

  I2C_ADDR = %0100_000_0

  N_IOPINS = 16

OBJ

VAR

PUB Init(n_I2C_lock, p_data, p_clock) ' also: handle the interrupt pins?
  I2C_lock := n_I2C_lock
  dataPin := ((p_data <# 31) #> 0)
  clockPin := ((p_clock <# 31) #> 0)

PUB read(device, pin) : value
  if 0 =< pin AND pin < 8
    value := expRead(device, GPIOA)
  if 8 =< pin AND pin < 16
    value := expRead(device, GPIOB)
  value >>= pin
  value &= 1

PUB write(device, pin, value)
  if 0 =< pin AND pin < 8
    readModifyWrite(device, GPIOA, pin, value)
  if 8 =< pin AND pin < 16
    readModifyWrite(device, GPIOB, pin-8, value)

PUB direction(device, pin, dir)
  if 0 =< pin AND pin < 8
    readModifyWrite(device, IODIRA, pin, dir)
  if 8 =< pin AND pin < 16
    readModifyWrite(device, IODIRB, pin-8, dir)

PRI readModifyWrite(device, reg, bit, value) | temp
  value &= 1
  bit #>= 0
  bit <#= 7
  
  temp := expRead(device, reg)
  temp &= $FFFFFFFE <- bit
  temp |= value << bit
  expWrite(device, reg, temp)
  
PRI expWrite(device, reg, value) | addr
  addr := getAddr(device)
  setLock
  I2C_start
  result := I2C_write(addr)
  result &= I2C_write(reg)
  result &= I2C_write(value)
  I2C_stop
  clearLock

PRI expRead(device, reg) : value | addr
  addr := getAddr(device)
  setLock
  I2C_start
  result := I2C_write(addr)
  result &= I2C_write(reg)
  if (result)
    I2C_stop
    I2C_start
    I2C_write(addr | 1)
    result := I2C_read(false)
  I2C_stop
  clearLock

PRI getAddr(device)
  return I2C_ADDR | device << 1

PRI I2C_write(value)
  value := ((!value) >< 8)
  repeat 8
    DIRA[dataPin] := value
    DIRA[clockPin] := false
    DIRA[clockPin] := true
    value >>= 1
  DIRA[dataPin] := false
  DIRA[clockPin] := false
  result := not(INA[dataPin])
  DIRA[clockPin] := true
  DIRA[dataPin] := true

PRI I2C_read(aknowledge)
  DIRA[dataPin] := false
  repeat 8
    result <<= 1
    DIRA[clockPin] := false
    result |= INA[dataPin]
    DIRA[clockPin] := true
  DIRA[dataPin] := (not(not(aknowledge)))
  DIRA[clockPin] := false
  DIRA[clockPin] := true
  DIRA[dataPin] := true

PRI I2C_start
  OUTA[dataPin] := false
  OUTA[clockPin] := false
  DIRA[dataPin] := true
  DIRA[clockPin] := true

PRI I2C_stop
  DIRA[clockPin] := false
  DIRA[dataPin] := false

PRI setLock
  if(I2C_lock)
    repeat while(lockset(I2C_lock))

PRI clearLock
  if(I2C_lock)
    lockclr(I2C_lock)

DAT
        dataPin         byte 29
        clockPin        byte 28
        I2C_lock        byte 00
