
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'


=begin
NOTES:
- How to send commands from controller?
- How to display output? Log+sensor?
- Separate 'dynamic state' schema?
  - sometimes we need an 'old' and a 'new' state, and the static piping layout is unchanged
  - the piping editor is only concerned with the static layout
- Pipes vs Joints vs Splitters: Joints and splitters are 1-way?
- Sensors only attached to pipes? Not so in the example
- Proposed change: Pipes to have exactly two elements, and Sensor moved to a non element (special widget attached to pipes)

TODO:
- Temperature propagation via convection

Options for simulator-controller communication:
a. separate threads talking thru shared event list, ie producer consumer
b. after each tick, make a call to the controller. easier, but a little contrived (cant work in real life))

Useful Physics laws
- Ideal gas law: PV = nRT, P=Pressure, V=volume, n=amount of gas (moles), R=universal gas constant, T=temperature
  = Pressure and volume are inversely proportionate
- Bernoulli's law: v^2 + p/p0 = constant, where v=velocity of flow, p=pressure, p0=density of fluid
  = velocity is inversely dependent on pressure difference
- atmospheric pressure is 101.352 kPa
- Poiseuille's Equation Calculator: V = (pi * P * r^4) / (8 * n * L)
    V = Volume per Second
    P = Pressure Difference Between The Two Ends
    R = Internal Radius of the Tube
    n = Absolute Viscosity
    L = Total Length of the Tube

=end

module Run
  def run(elem, *args)
    send("run_#{elem.schema_class.name}", elem, *args)
  end

  def run_Pipe(elem, new_elem)
  end

  def run_Joint(elem, new_elem)
    #funnel fluids from pipes into one pipe
    #total flow is conserved
    elem.output.flow = elem.pipes.inject(0) {|memo,p| memo+p.flow}
    if elem.output.flow > 0
      elem.output.temperature = elem.pipes.inject(0) {|memo,p|memo + p.temperature * p.flow} / elem.output.flow
    end
  end

  def run_Splitter(elem, new_elem)
    #shares fluids from one pipe to others
    #total flow is conserved
    #final velocity is equal for all output pipes
    total_area = [elem.left, elem.right].inject(0) {|memo,p| memo+p.area }
    velocity = elem.input.flow / total_area
    [elem.left, elem.right].each do |p|
      p.flow = p.area * velocity
      p.temperature = elem.input.temperature
    end
  end

  def run_Source(elem, new_elem)
    #allows material to enter the system
    #pressure is assumed to be maintained by environment
  end

  def run_Exhaust(elem, new_elem)
    #allows material to exit the system
    #pressure is maintained at atmospheric pressure (~101 kPa)
  end

  def run_Burner(elem, new_elem)
    #burner heats up water that passes through it
    elem.output.temperature = elem.temperature
    transfer_water(elem.input, elem.output)
  end

  def run_Radiator(elem, new_elem)
    #radiator uses the heat from the passing water to heat the environment
    elem.temperature = elem.input.temperature
    transfer_water(elem.input, elem.output)
  end

  def run_Vessel(elem, new_elem)
    #Allows material to fill up the vessel. Once filled it acts like a joint
    if elem.contents < elem.capacity
      transfer = (input *3.14/4) * sqrt(input.pressure/100 - 1) * 10
      input.pressure = (input.pressure*input.volume - transfer) / input.volume
      elem.contents += transfer
      dirty_pipe(input)
    else #behave like a joint
      transfer_water(elem.input, elem.output)
    end
  end

  def run_Valve(elem, new_elem)
    #throttles the flow of water through a pipe
  end

  def run_Pump(elem, new_elem)
    #raises the flow of the output pipe
    transfer_water(elem.input, elem.output)
    elem.output.flow = elem.flow
  end

  #transfer some amount of water from s1 to s2 based on connecting area and flow (based on pressure)
  def transfer_water(p1, p2)
    p2.flow = p1.flow
    p2.temperature = p1.temperature
  end
end

class Simulator

  include Run

  def initialize(piping)
    @piping = piping
    #do initialization here by setting the default states of the pipes, etc
  end

  #will run continuously
  def execute
    while true
      tick
    end
  end

  #main step function. each step takes the current state and produces the next state
  #maintains a dirty bit on elements to know which elements are connected to pipes whose state have changed
  def tick
    @piping.elements.each {|e| run(e,0)}
  end

end