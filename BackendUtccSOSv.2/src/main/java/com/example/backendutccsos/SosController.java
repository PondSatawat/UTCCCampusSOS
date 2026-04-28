package com.example.backendutccsos;

import java.util.List;
import java.util.Map; // ต้องมีเพื่อรับค่า JSON ตอนอัปเดตสถานะ

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

@RestController
@RequestMapping("/api/sos")
@CrossOrigin(origins = "*") 
public class SosController {

    @Autowired
    private SosRepository sosRepository;

    // 1. รับแจ้งเหตุและส่งแจ้งเตือนหา Admin
    @PostMapping("/request")
    public String createRequest(@RequestBody SosReq request) {
        sosRepository.save(request);
        
        try {
            Message message = Message.builder()
                .putData("type", "SOS_EMERGENCY") 
                .setTopic("admin_alerts") 
                .setNotification(Notification.builder()
                    .setTitle("มีเหตุฉุกเฉินด่วน!")
                    .setBody("ปัญหา: " + request.getProblemType() + " ที่ " + request.getLocationName())
                    .build())
                .build();
            FirebaseMessaging.getInstance().send(message); 
        } catch (Throwable e) {
            e.printStackTrace(); 
        }
        return "สำเร็จ! รับแจ้งเหตุปัญหา: " + request.getProblemType() + " เรียบร้อยแล้ว ทีมช่างกำลังดำเนินการ";
    }

    // 2. ดึงประวัติทั้งหมด (ของ Admin) ให้เรียงจากใหม่ไปเก่า
    @GetMapping("/all")
    public List<SosReq> getAllRequests() {
        return sosRepository.findAllByOrderByCreatedAtDesc(); 
    }

    // 3. ดึงประวัติส่วนตัว (ของ User) ให้เรียงจากใหม่ไปเก่า
    @GetMapping("/user/{userId}")
    public List<SosReq> getHistoryByUserId(@PathVariable String userId) {
        return sosRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    // 4. อัปเดตสถานะและส่งแจ้งเตือนกลับหา User ตัวจริง
    @PutMapping("/updateStatus/{id}")
    public String updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        SosReq req = sosRepository.findById(id).orElse(null);
        if (req != null) {
            String newStatus = body.get("status"); 
            req.setStatus(newStatus); 
            sosRepository.save(req);
            
            // ส่งแจ้งเตือนกลับหา User
            try {
                Message message = Message.builder()
                    .putData("type", "STATUS_UPDATE")
                    .putData("sosId", id.toString())
                    .setTopic("user_" + req.getUserId()) // ส่งไปที่เฉพาะของ User คนที่แจ้ง
                    .setNotification(Notification.builder()
                        .setTitle("อัปเดตสถานะการช่วยเหลือ")
                        .setBody("คำขอของคุณได้รับการเปลี่ยนสถานะเป็น: " + newStatus) 
                        .build())
                    .build();
                FirebaseMessaging.getInstance().send(message);
            } catch (Exception e) {
                e.printStackTrace();
            }
            return "อัปเดตสถานะสำเร็จ";
        }
        return "ไม่พบข้อมูล";
    }
}