import { Component } from '@angular/core';
import { BackgroundGeolocation, BackgroundGeolocationConfig, BackgroundGeolocationResponse, BackgroundGeolocationEvents } from '@awesome-cordova-plugins/background-geolocation/ngx';
import { Platform } from '@ionic/angular';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://qcbcjyhqgxwuqutzkxrh.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjYmNqeWhxZ3h3dXF1dHpreHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMDE3NjQsImV4cCI6MjA2Njc3Nzc2NH0.y-hQVa6nzBpCMpXL7XbcWPMGafATvnMez3lAmFvb2zY';
const supabase = createClient(supabaseUrl, supabaseKey);

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
})
export class HomePage {
  phone = '';
  password = '';
  loading = false;
  errorMsg = '';
  loggedIn = false;
  employee: any = null;

  constructor(
    private backgroundGeolocation: BackgroundGeolocation,
    private platform: Platform
  ) {
    this.platform.ready().then(() => {
      this.checkSession();
    });
  }

  async login() {
    this.errorMsg = '';
    if (!this.phone || !this.password) {
      this.errorMsg = 'يرجى إدخال رقم الهاتف وكلمة المرور';
      return;
    }
    this.loading = true;
    try {
      const { data, error } = await supabase.rpc('authenticate_employee', {
        employee_phone: this.phone,
        employee_password: this.password
      });
      if (error || !data.success) {
        this.errorMsg = 'خطأ في رقم الهاتف أو كلمة المرور';
        this.loading = false;
        return;
      }
      this.employee = data.employee;
      this.loggedIn = true;
      localStorage.setItem('employee_session', JSON.stringify(this.employee));
      await supabase.from('employees').update({ status: 'active' }).eq('id', this.employee.id);
      this.startBackgroundTracking();
    } catch (err) {
      this.errorMsg = 'حدث خطأ في الاتصال';
    }
    this.loading = false;
  }

  logout() {
    this.loading = true;
    this.stopBackgroundTracking();
    if (this.employee) {
      supabase.from('employees').update({ status: 'inactive' }).eq('id', this.employee.id);
    }
    localStorage.removeItem('employee_session');
    this.employee = null;
    this.loggedIn = false;
    this.loading = false;
  }

  checkSession() {
    const session = localStorage.getItem('employee_session');
    if (session) {
      this.employee = JSON.parse(session);
      this.loggedIn = true;
      this.startBackgroundTracking();
    }
  }

  startBackgroundTracking() {
    if (!this.employee) return;
    const config: BackgroundGeolocationConfig = {
      desiredAccuracy: 10,
      stationaryRadius: 20,
      distanceFilter: 30,
      debug: false,
      stopOnTerminate: false,
      startOnBoot: true,
      interval: 10000,
      notificationTitle: 'تتبع الموقع',
      notificationText: 'يتم تتبع موقعك في الخلفية'
    };
    this.backgroundGeolocation.configure(config).then(() => {
      this.backgroundGeolocation.on(BackgroundGeolocationEvents.location).subscribe(async (location: BackgroundGeolocationResponse) => {
        // أرسل الموقع إلى Supabase
        try {
          await supabase.from('logs').insert([{
            employee_id: this.employee.id,
            center_id: this.employee.center_id,
            action: 'background_tracking',
            latitude: location.latitude,
            longitude: location.longitude,
            accuracy: location.accuracy,
            occurred_at: new Date().toISOString(),
            notes: 'تتبع تلقائي من التطبيق'
          }]);
        } catch (e) {
          // يمكن حفظها محليًا إذا أردت
        }
      });
    });
    this.backgroundGeolocation.start();
  }

  stopBackgroundTracking() {
    this.backgroundGeolocation.stop();
  }
} 