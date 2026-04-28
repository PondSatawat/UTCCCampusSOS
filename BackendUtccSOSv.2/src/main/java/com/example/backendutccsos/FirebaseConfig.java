package com.example.backendutccsos;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void init() {
        try {
            //get key from serviceAccountKey.json in resources folder
            InputStream serviceAccount = getClass().getClassLoader().getResourceAsStream("serviceAccountKey.json");
            
            if (serviceAccount == null) {
                System.out.println("Key not found!");
                return;
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("Firebase Admin Connected!");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}