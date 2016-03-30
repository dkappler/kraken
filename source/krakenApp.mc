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

using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class krakenApp extends App.AppBase {


	// our storage, right now a thin wrapper
	// for the fit file, but in future we might have
	// better access
	var fio_;
	
    function initialize() {
        AppBase.initialize();
    	fio_ = new krakenFileIO();
    }

    //! onStart() is called on application start up
    function onStart() {
    	fio_.open();
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    	fio_.close();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new krakenView(fio_), new krakenDelegate() ];
    }

}
