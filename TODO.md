# Gilda Medical - Production Upgrade Checklist

## ✅ Completed
- [x] User Registration API (register/login/pending/approve/reject)
- [x] Registration status: pending/approved/rejected
- [x] Admin approval panel (API + Flutter screen)
- [x] Registration alert to admin on new signup
- [x] Password hashing (werkzeug + bcrypt in requirements)
- [x] JWT on all API routes
- [x] JWT secret from environment variable (.env.example)
- [x] Role-based access control (admin/pharmacist/staff)
- [x] utils/auth.py - roles_required() decorator
- [x] Attendance model (check-in/check-out/present/late/absent/holiday)
- [x] Salary deduction: absent=-500, late=-100
- [x] Monthly salary calculation via services/staff_service.py
- [x] Employee Reward System (best employee API + Flutter screen)
- [x] Barcode scanner migrated to mobile_scanner (billing screen)
- [x] Dashboard: staff attendance summary card added
- [x] Dashboard: alerts unread count card added
- [x] Splash screen with Gilda logo + animation
- [x] Material 3 + rounded cards + Poppins font
- [x] Sales analytics chart (fl_chart, 14-day line chart)
- [x] Expiry/low-stock/fraud/registration alerts
- [x] Code structure: routes/ models/ services/ utils/
- [x] python-dotenv for environment variable loading
- [x] rewards blueprint registered in app.py

## 🔲 Optional Future Improvements
- [ ] Per-staff sales tracking (link Sale to User/Staff)
- [ ] Customer feedback system for reward scoring
- [ ] Push notifications (FCM) for alerts
- [ ] PDF bill generation (pdf + printing packages ready)
- [ ] Fraud detection ML model
- [ ] Logo image asset (SVG/PNG) in assets/logo/
