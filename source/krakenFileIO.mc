//!
//!  Copyright 2016 Daniel Kappler (daniel.kappler@gmail.com)
//!  
//!  Licensed under the Apache License, Version 2.0 (the "License");
//!  you may not use this file except in compliance with the License.
//!  You may obtain a copy of the License at
//!
//!    http://www.apache.org/licenses/LICENSE-2.0
//!
//!  Unless required by applicable law or agreed to in writing, software
//!  distributed under the License is distributed on an "AS IS" BASIS,
//!  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//!  See the License for the specific language governing permissions and
//!  limitations under the License.
//!

using Toybox.System as Sys;
using Toybox.ActivityRecording as Ar;

class krakenFileIO {
	// This class should actually open a file
	// and allow to store an arbitrary value similar to python
	// or any other language
	// For the time being we exploit the log file of 
	// Garmin to store our data
	// The upper limit of the log file is apparently 5kb
	// Hence we have to keep the number of values to
	// store to a bare minimum
	
	// we know the upper limit
	var max_size_;
	
	// some primitive version inspired huffman code 
	// to use ascii strings to print the heart rate
	// this far from ideal and should not be required.
	// currently the log file is also not generated
	// on the watch
	var huffman_dict_;
	
	// an actual fit session which stores creates
	// a new activity whenever this app runs
	var session_;
	
	function initialize(){
		
		// 5kb
		max_size_ = 5*1024;
		
		// our huffman like encoding is for values between
		// 30 and 200
		// we have the ascii characters for a-z A-Z 0-9 `~@#$%^&*()_=+[{]}\|;"',<.>/? 
		//                                  26  26  10  30 
		//(space is also a symbol which we use to encode infrequent values)
		// 92
		huffman_dict_ = {};
		// 30-44 space plus unique
		huffman_dict_[30] = " a";
		huffman_dict_[31] = " b";
		huffman_dict_[32] = " c";
		huffman_dict_[33] = " d";
		huffman_dict_[34] = " e";
		huffman_dict_[35] = " f";
		huffman_dict_[36] = " g";
		huffman_dict_[37] = " h";
		huffman_dict_[38] = " i";
		huffman_dict_[39] = " j";
		huffman_dict_[40] = " k";
		huffman_dict_[41] = " m";
		huffman_dict_[42] = " n";
		huffman_dict_[43] = " o";
		huffman_dict_[44] = " p";
		huffman_dict_[45] = " q";
		
		// 45-137  get a unique symbol
		huffman_dict_[45] = "a";
		huffman_dict_[46] = "b";
		huffman_dict_[47] = "c";
		huffman_dict_[48] = "d";
		huffman_dict_[49] = "e";
		huffman_dict_[50] = "f";
		huffman_dict_[51] = "g";
		huffman_dict_[52] = "h";
		huffman_dict_[53] = "i";
		huffman_dict_[54] = "j";
		huffman_dict_[55] = "k";
		huffman_dict_[56] = "l";
		huffman_dict_[57] = "m";
		huffman_dict_[58] = "n";
		huffman_dict_[59] = "o";
		huffman_dict_[60] = "p";
		huffman_dict_[61] = "q";
		huffman_dict_[62] = "r";
		huffman_dict_[63] = "s";
		huffman_dict_[64] = "t";
		huffman_dict_[65] = "u";
		huffman_dict_[66] = "v";
		huffman_dict_[67] = "w";
		huffman_dict_[68] = "x";
		huffman_dict_[69] = "y";
		huffman_dict_[70] = "z";
		huffman_dict_[71] = "A";
		huffman_dict_[72] = "B";
		huffman_dict_[73] = "C";
		huffman_dict_[74] = "D";
		huffman_dict_[75] = "E";
		huffman_dict_[76] = "F";
		huffman_dict_[77] = "G";
		huffman_dict_[78] = "H";
		huffman_dict_[79] = "I";
		huffman_dict_[80] = "J";
		huffman_dict_[81] = "K";
		huffman_dict_[82] = "L";
		huffman_dict_[83] = "M";
		huffman_dict_[84] = "N";
		huffman_dict_[85] = "O";
		huffman_dict_[86] = "P";
		huffman_dict_[87] = "Q";
		huffman_dict_[88] = "R";
		huffman_dict_[89] = "S";
		huffman_dict_[90] = "T";
		huffman_dict_[91] = "U";
		huffman_dict_[92] = "V";
		huffman_dict_[93] = "W";
		huffman_dict_[94] = "X";
		huffman_dict_[95] = "Y";
		huffman_dict_[96] = "Z";
		huffman_dict_[97] = "0";
		huffman_dict_[98] = "1";
		huffman_dict_[99] = "2";
		huffman_dict_[100] = "3";
		huffman_dict_[101] = "4";
		huffman_dict_[102] = "5";
		huffman_dict_[103] = "6";
		huffman_dict_[104] = "7";
		huffman_dict_[105] = "8";
		huffman_dict_[106] = "9";
		huffman_dict_[107] = "!";
		huffman_dict_[108] = "@";
		huffman_dict_[109] = "#";
		huffman_dict_[110] = "$";
		huffman_dict_[111] = "%";
		huffman_dict_[112] = "^";
		huffman_dict_[113] = "&";
		huffman_dict_[114] = "*";
		huffman_dict_[115] = "(";
		huffman_dict_[116] = ")";
		huffman_dict_[117] = "-";
		huffman_dict_[118] = "_";
		huffman_dict_[119] = "=";
		huffman_dict_[120] = "+";
		huffman_dict_[121] = "[";
		huffman_dict_[122] = "{";
		huffman_dict_[123] = "]";
		huffman_dict_[124] = "}";
		huffman_dict_[125] = "\\";
		huffman_dict_[126] = "|";
		huffman_dict_[127] = ";";
		huffman_dict_[128] = "'";
		huffman_dict_[129] = "\"";
		huffman_dict_[130] = ",";
		huffman_dict_[131] = "<";
		huffman_dict_[132] = ".";
		huffman_dict_[133] = ">";
		huffman_dict_[134] = "/";
		huffman_dict_[135] = "?";
		huffman_dict_[136] = "`";
		huffman_dict_[137] = "~";
		
		// 135-200  space plus unique
		huffman_dict_[128] = " r";
		huffman_dict_[129] = " s";
		huffman_dict_[130] = " t";
		huffman_dict_[131] = " u";
		huffman_dict_[132] = " v";
		huffman_dict_[133] = " w";
		huffman_dict_[134] = " x";
		huffman_dict_[135] = " y";
		huffman_dict_[136] = " z";
		huffman_dict_[137] = " A";
		huffman_dict_[138] = " B";
		huffman_dict_[139] = " C";
		huffman_dict_[140] = " D";
		huffman_dict_[141] = " E";
		huffman_dict_[142] = " F";
		huffman_dict_[143] = " G";
		huffman_dict_[144] = " H";
		huffman_dict_[145] = " I";
		huffman_dict_[146] = " J";
		huffman_dict_[147] = " K";
		huffman_dict_[148] = " L";
		huffman_dict_[149] = " M";
		huffman_dict_[150] = " O";
		huffman_dict_[151] = " P";
		huffman_dict_[152] = " Q";
		huffman_dict_[153] = " R";
		huffman_dict_[154] = " S";
		huffman_dict_[155] = " T";
		huffman_dict_[156] = " U";
		huffman_dict_[157] = " V";
		huffman_dict_[158] = " W";
		huffman_dict_[159] = " X";
		huffman_dict_[160] = " Y";
		huffman_dict_[161] = " Z";
		huffman_dict_[162] = " 0";
		huffman_dict_[163] = " 1";
		huffman_dict_[164] = " 2";
		huffman_dict_[165] = " 3";
		huffman_dict_[166] = " 4";
		huffman_dict_[167] = " 5";
		huffman_dict_[168] = " 6";
		huffman_dict_[169] = " 7";
		huffman_dict_[170] = " 8";
		huffman_dict_[171] = " 9";
		huffman_dict_[172] = " !";
		huffman_dict_[173] = " @";
		huffman_dict_[174] = " #";
		huffman_dict_[175] = " $";
		huffman_dict_[176] = " %";
		huffman_dict_[177] = " ^";
		huffman_dict_[178] = " &";
		huffman_dict_[179] = " *";
		huffman_dict_[180] = " (";
		huffman_dict_[181] = " )";
		huffman_dict_[182] = " -";
		huffman_dict_[183] = " _";
		huffman_dict_[184] = " =";
		huffman_dict_[185] = " +";
		huffman_dict_[186] = " [";
		huffman_dict_[187] = " {";
		huffman_dict_[188] = " ]";
		huffman_dict_[189] = " }";
		huffman_dict_[190] = " \\";
		huffman_dict_[191] = " |";
		huffman_dict_[192] = " ;";
		huffman_dict_[193] = " '";
		huffman_dict_[194] = " \"";
		huffman_dict_[195] = " ,";
		huffman_dict_[196] = " <";
		huffman_dict_[197] = " .";
		huffman_dict_[198] = " >";
		huffman_dict_[199] = " /";
		huffman_dict_[200] = " ?";
	}

	function writeln_str(value){
		Sys.print("s:");
		Sys.print(value);
		println();
	}
	
	function init_hr(value){
		Sys.print("h:");
	}
	
	function write_hr(value){
		// we want to track this value
		// so this will create most of the data 
		// we use huffman encoding for that to save storage size
		try {
			// we don't need new lines since we use huffman dict
		    // if the value is supported
			Sys.print(huffman_dict_[value]);
		}
		catch(ex){
			Sys.print("!");
		}
	}
	
	function open(){
		// using the fit api we can create a fit file if the session 
		// is not closed we close it and start a new session
		if( session_ != null){
			close();
		}
        var clock_time = Sys.getClockTime();
        var name = "kraken_"+clock_time.hour.toString()+"_"+clock_time.min.toString();
		session_ = Ar.createSession({:name=>name});
		session_.start();
	}
	
	function close(){
		// we make sure that our session gets closed
		if( session_ != null){
			if( session_.isRecording()){
				session_.stop();
			}
			session_.save();
			session_ = null;
		}
	}
	
}