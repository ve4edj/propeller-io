{{
  The following is an object that coordinates IO access transparently between the onboard Propeller pins and
  an external MCP23017 I2C IO expander IC.

  This code was written by Erik Johnson (originally for UMSAE - Formula Electric)
}}

CON
  #0,INPUT,OUTPUT
  #0,LOW,HIGH
  
  N_PROPPINS = 32

OBJ
  IOEXP    : "MCP23017"

VAR
  
PUB Init(n_IOexp, I2C_lock, I2C_data_p, I2C_clock_p)
  totalPins := N_PROPPINS
  totalPins += n_IOexp * IOEXP#N_IOPINS
  IOEXP.Init(I2C_lock, I2C_data_p, I2C_clock_p)
  
PUB read(pin)
  if validPin(pin)
    if propPin(pin)
      return INA[pin]
    else
      return IOEXP.read(getExpIdx(pin), getExpPin(pin))

PUB write(pin, value)
  value &= 1
  if validPin(pin)
    if propPin(pin)
      OUTA[pin] := value
    else
      IOEXP.write(getExpIdx(pin), getExpPin(pin), value)

PUB direction(pin, dir)
  dir &= 1
  if validPin(pin)
    if propPin(pin)
      DIRA[pin] := dir
    else
      if dir == INPUT
        IOEXP.direction(getExpIdx(pin), getExpPin(pin), IOEXP#INPUT)
      if dir == OUTPUT
        IOEXP.direction(getExpIdx(pin), getExpPin(pin), IOEXP#OUTPUT) 

PRI validPin(pin)
  if 0 =< pin AND pin < totalPins
    return TRUE
  return FALSE

PRI propPin(pin)
  return pin < N_PROPPINS

PRI getExpIdx(pin)
  return ((pin - N_PROPPINS) / IOEXP#N_IOPINS)

PRI getExpPin(pin)
  return ((pin - N_PROPPINS) // IOEXP#N_IOPINS)

DAT
        numExp          byte 00
        totalPins       byte 00
