#include <GenericIPBus/GenericIPBus.hh>
#include <BUTool/ToolException.hh>
#include <iostream>
#include <iomanip> 

void GenericIPBus::DebugDump(std::ostream & output){
  //Get all the register names
  std::vector<std::string> registers = myMatchRegex("*");
  int sleepLength=1;
  
  //read out each
  uint32_t val;  
  for(std::vector<std::string>::iterator itReg = registers.begin();
      itReg != registers.end();
      ++itReg){
    //Name
    output << std::setw(60) << std::setfill(' ') << std::right << *itReg;
    output << " : ";
    try{
      val = RegReadRegister(*itReg);
      output << "0x" << std::setfill('0') << std::setw(8) << std::hex << val << std::endl;
    }catch(BUException::REG_READ_DENIED & e){
      output << "Write Only" << std::endl;
    }

  }
  output << "\n\n" 
	 << "============================================================\n"
	 << "== Sleep: " << sleepLength  << "s\n"
	 << "============================================================\n"
	 << "\n\n";
  sleep(sleepLength);
  for(std::vector<std::string>::iterator itReg = registers.begin();
      itReg != registers.end();
      ++itReg){
    //Name
    output << std::setw(60) << std::setfill(' ') << std::right << *itReg;
    output << " : ";
    try{
      val = RegReadRegister(*itReg);
      output << "0x" << std::setfill('0') << std::setw(8) << std::hex << val << std::endl;
    }catch(BUException::REG_READ_DENIED & e){
      output << "Write Only" << std::endl;
    }

  }
}
