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

using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Time as Time;
using Toybox.Math as Ma;


class krakenView extends Ui.View {

	// the sensor which is wrapped
	// right now we only check the heart rate
	// in future this should also contain temperature
	// however, deactivation is not supported right now
	var sensor;
	
	var initialized_;
	// we need a timer to trigger the update
	var timer_;
	
	// our storage, right now a thin wrapper
	// for the fit file, but in future we might have
	// better access
	var fio_;
	
	// array with the heart rate history
	var hr_history_;
	// the latest value we did write
	var hr_history_cur_;
	
	// the main update frequency of the 
    var update_frequency_;

    function initialize() {
    	// we update ones per minute
	    update_frequency_ = 60;
	    // Sys.println("DEBUG MODE HIGH FREQUENCY UPDATE");
	    // update_frequency_ = 1;
	    // todo add recording using the record sample
	    // todo use sytem stats for battery
	    // add date
	    // add steps
        View.initialize();
    	fio_ = new krakenFileIO();
    	initialized_ = false;
    	
    
    	// heart rate plot lower 20 - 194 upper with 2 pixel width -> 88
    	hr_history_ = new[88];
    	for(var i = 0; i < hr_history_.size(); i += 1){
    		hr_history_[i] = 0;
    	}
    	hr_history_cur_ = 0;
    	
    	// todo 
    	// these sensor readings should be done by a settings file
    	// or the user should be able to set it
    	var frequency = update_frequency_;
    	var window = 15;
        // we read out our sensor
        // todo include temperature
        // right now we only plot the hr
        sensor = new krakenSensor(frequency, window, fio_);
        
        // initialize the ui update timer
    	timer_ = new Timer.Timer();
        initialize_();
    }

    //! Load your resources here
    function onLayout(dc) {
    }

    //! Update the view
    // this function is called every min
    function onUpdate(dc) {
        var clock_time = Sys.getClockTime();
        //Sys.println("clock time " + clock_time.hour.toString() + " : " clock_time.min.toString() + " : " + clock_time.sec.toString() );
        //var time = " update clock clock time " + clock_time.hour + " : " + clock_time.min + " : " + clock_time.sec;
        //Sys.println(time);
        
        // Call the parent onUpdate function to redraw the layout
        // not really in use right now, we draw the layout ourselves 
        View.onUpdate(dc);
        
        // this is not optimal but for the first version it 
        // seems to do the job
        update_date_(dc);
        update_time_(dc, clock_time);
        update_hr_(dc, sensor.get_hr());
        var stats = Sys.getSystemStats();
        update_battery_(dc, stats.battery);
    }
    
    function update_date_(dc){
    	// we visualize the current day month and year
    	var now = Time.now();	
    	var info = Calendar.info(now, Time.FORMAT_LONG);
    	var date = Lang.format("$1$ $2$ $3$", 
    						   [info.day, info.month, info.year]);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
 		var center_x = dc.getWidth()/2;
        dc.drawText(center_x, 20, 
        			Gfx.FONT_MEDIUM, 
        			date, 
        			Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function update_time_(dc, clock_time){
    	// visualize the current time
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
 		var center_x = dc.getWidth()/2;
        var center_y = dc.getHeight()/2;
        
        // todo 
        // check if this can be done using Lang.format
        var current_time = "";
        if (clock_time.hour < 10){
        	current_time += "0";
        }
        current_time += clock_time.hour.toString();
        current_time += ":";
        if (clock_time.min < 10){
        	current_time += "0";
        }
        current_time += clock_time.min.toString();
        dc.drawText(center_x, 
        			30, 
        			Gfx.FONT_NUMBER_THAI_HOT, 
        			current_time, 
        			Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function update_battery_(dc, battery){
    	// battery is given in 0-100 percent
    	var br_tmp = battery.toLong();
    	// don't like this hard coded 
    	// this should be a user option
    	// for now it is just easier like this
    	if (br_tmp > 75){
        	dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        } else if (br_tmp > 30) {
        	dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
        } else if (br_tmp > 15) {
        	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        } else{
        	dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        }
        dc.drawText(160, -5, 
        			Gfx.FONT_MEDIUM, 
        			br_tmp.toString()+" Bat", 
        			Gfx.TEXT_JUSTIFY_RIGHT);
    }
    
    function update_hr_(dc, hr){
    	// debugging for heart rate
    	// for plotting we can easily generate different
    	// beats per minute with random
    	// motion
    	// hr += Ma.rand()%20-10;
    	// Sys.println("hr " + hr.toString());
    	if (hr < 90){
        	dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        } else if (hr < 120) {
        	dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
        } else if (hr < 140) {
        	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        } else{
        	dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        }
        dc.drawText(95, -5, Gfx.FONT_MEDIUM, hr.toString()+" Hr", Gfx.TEXT_JUSTIFY_RIGHT);
        
        
        hr_history_[hr_history_cur_] = hr;
        // we have 88 values we set the values for the last 88 min
        
        var hr_pos = hr_history_cur_;
        var hr_tmp;
        var fill_height = 0;
        // 50 pixel -> 40-140 -> 2 pixel = 1 hr
        for( var x = 194; x >= 20; x -= 2){
        	hr_tmp = hr_history_[hr_pos];
        	// we set the background color 
        	// this is again hard coded 
	    	if (hr_tmp < 90){
	        	dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
	        } else if (hr_tmp < 120) {
	        	dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
	        } else if (hr_tmp < 140) {
        		dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        	} else {
        		dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        	}
	      	dc.fillRectangle(x, 130, 2, 50);
	      	
        	// we set the fill height
	        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        	if (hr_tmp < 40) {
        		fill_height = 50;
        	} else if (hr_tmp > 140) {
        		fill_height = 0;
        	} else {
        		fill_height = 50 - (hr_tmp-40)/2;
        	}
	      	dc.fillRectangle(x, 130, 2, fill_height);
	      	
	      	// we iterate through our position in the hr_history
	      	// this takes care of the special case when we would
	      	// index below 0
	      	hr_pos = (hr_pos - 1);
	      	if (hr_pos < 0) {
	      		hr_pos = hr_history_.size()-1;
	      	}
      	}
      	// gray color lines to indicate what the heart rate means
	    dc.setColor(0x888888, Gfx.COLOR_TRANSPARENT);
      	// bottom line
	    dc.drawLine(20, 179, 194, 179);
	    dc.drawLine(20, 155, 194, 155);
	    dc.drawLine(20, 130, 194, 130);
        dc.drawText(40, 130, Gfx.FONT_XTINY, "140", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(48, 145, Gfx.FONT_XTINY, " 90", Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(56, 160, Gfx.FONT_XTINY, " 40", Gfx.TEXT_JUSTIFY_RIGHT);
	    
        // setting the next entry
        hr_history_cur_ = (hr_history_cur_ + 1) % hr_history_.size();
    }
    
    function initialize_(){
        var clock_time = Sys.getClockTime();
    	if (clock_time.sec == 0){
    		// every minute we update our ui
    		timer_.start(method(:request_update_), update_frequency_*1000, true);
    		// we have to request an update
    		request_update_();
    	}
    	else{
    		// we wait until we are at 0 sec
    		// right now we call this function till we are at 
    		timer_.start(method(:initialize_), 1000);
    	}
    }
    
    function request_update_(){
    	Ui.requestUpdate();
    }


    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    	fio_.open();
    }
    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    	fio_.close();
    }

}
