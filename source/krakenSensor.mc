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
using Toybox.Lang as Lang;
using Toybox.Sensor as Snsr;
using Toybox.Timer as Timer;

class krakenSensor 
{
	// endless count
	var count_;
	// write the latest entry
	var hr_window_pos_;
	// this is filled for filtering
	var hr_window_;
	// this is used externally to show the heart rate
	var hr_;
	// we sample in this frequency
	var frequency_;
	
	// we need a timer to start the sampling
	var timer_;
	// the second offset to start sampling
	var sec_offset_;
	var frequencies_ = [1,30,60,120,300,600,1200];
	
	// file io 
	var fio_;
	
	var sensors_;
	
    //! Constructor
    function initialize(frequency, window, fio)
    {
    	fio_ = fio;
    	frequency_ = frequency;
    	var window_ = window;
    	// we only allow for frequency
    	// 	1  = > every   1 sec
    	// 	60  = > every  1 min
    	// 	120  = > every 2 min
    	// 	300  = > every 5 min
    	// 	600  = > every 10 min
    	// 	1200 = > every 20 min
    	
    	// some checks to make sure we are always valid
    	var frequency_valid = false;
    	for( var i = 0; i < frequencies_.size(); i++ ) {
    		if (frequency_ == frequencies_[i]){
    			frequency_valid = true;
    		}
		}
		if (!frequency_valid){
			window_ = 1;
			frequency_ = 1;
		}
		if (frequency_ < 1){
			window_ = 1;
			frequency_ = 1;
		}
		if (window_ < 1){
			window_ = 1;
			frequency_ = 1;
		}
		if (window_ > 59){
			window_ = 59;
		}
		if (frequency_ == 1){
			window_ = 1;
		}
	    count_ = 1;
	    // we start sampling in between a minute
    	sec_offset_ = 30-window_/2;
    	hr_window_ = new[window_];
    	hr_window_pos_ = 0;
    	hr_ = 0;
    	
    	timer_ = new Timer.Timer();
    	if( frequency_ > 1){
    		timer_.start(method(:sec_offset_initialize_), 1000);
    	} else{
    		start_sensor_();
    	}
    }
    
    function sec_offset_initialize_(){
        var clock_time = Sys.getClockTime();
        //var time = "clock time " + clock_time.hour + " : " + clock_time.min + " : " + clock_time.sec;
        //Sys.println(clock_time.min.toString() + " : " + clock_time.sec.toString());
        // we start our timer for the frequency loop 
    	if (clock_time.sec == sec_offset_){
    		timer_.start(method(:start_sensor_), frequency_*1000, true);
    	}
    	else{
    		// we are not there yet so we call ourself
    		timer_.start(method(:sec_offset_initialize_), 1000);
    	}
    }
    
    function start_sensor_(){
        // var clock_time = Sys.getClockTime();
        // Sys.println("start sensor"+ clock_time.min.toString() + " : " + clock_time.sec.toString());
        hr_window_pos_ = 0;
        //Snsr.setEnabledSensors( [Snsr.SENSOR_HEARTRATE,Snsr.SENSOR_TEMPERATURE ] );
        sensors_ = Snsr.setEnabledSensors( [Snsr.SENSOR_HEARTRATE] );
        Snsr.enableSensorEvents( method(:on_snsr_) );
    }
    
    function stop_sensor_(){
        //var clock_time = Sys.getClockTime();
        //Sys.println("stop "+clock_time.min.toString() + " : " + clock_time.sec.toString());
        Snsr.enableSensorEvents(null);
        sensors_ = Snsr.setEnabledSensors([]);
    }
    
    function get_hr(){
    	return hr_;
    }
    
    function update_hr_(){
    	// computing the mean hr
    	var sum = 0;
    	for( var i = 0; i < hr_window_.size(); ++i ) {
    		sum += hr_window_[i];
		}
		sum /= hr_window_.size();
		hr_ = sum;
	    fio_.write_hr(hr_);
    }
    
    function on_snsr_(sensor_info)
    {
        var HR = sensor_info.heartRate;
        //if( sensor_info.temperature != null ){
        	// Sys.println("temp "+sensor_info.temperature.toString());
        //}
        if( sensor_info.heartRate != null )
        {
        	// the modulo operations should never be required
        	// but we want to be safe
        	hr_window_[hr_window_pos_%hr_window_.size()] = HR;
        	// var msg = "update window " + hr_window_pos_ + " :: " + HR.toString() + " ws " + hr_window_.size().toString();
        	// Sys.println(msg);
        	hr_window_pos_ += 1;
	        // special case we 
	        if (hr_window_.size() > 1){
	        	if (hr_window_pos_ >= hr_window_.size()){
	        		stop_sensor_();
	        		update_hr_();
	        	}
	        }else{
	        	hr_window_pos_ = 0;
	        	// special case for high frequency of one sec
	        	// we dont have a window so we always take the latest
	        	hr_ = hr_window_[0];
		        fio_.write_hr(hr_);
	        }
        }
    }
}