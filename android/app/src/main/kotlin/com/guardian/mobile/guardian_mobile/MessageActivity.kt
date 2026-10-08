package com.guardian.mobile.guardian_mobile

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class MessageActivity : Activity() {
    companion object {
        const val EXTRA_MESSAGE_TEXT = "extra_message_text"
        const val EXTRA_CONTACT_PHONE = "extra_contact_phone"
        const val EXTRA_COMMAND_ID = "extra_command_id"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Turn screen on and show over lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val messageText = intent.getStringExtra(EXTRA_MESSAGE_TEXT) ?: "Este dispositivo está protegido por Guardian Mobile."
        val contactPhone = intent.getStringExtra(EXTRA_CONTACT_PHONE)
        val commandId = intent.getStringExtra(EXTRA_COMMAND_ID)

        // Report EXECUTED when message is displayed
        if (!commandId.isNullOrEmpty()) {
            CommandAckClient.sendAck(applicationContext, commandId, "EXECUTED")
        }

        // Programmatic UI
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFF0F172A.toInt()) // AppColors.primary
            setPadding(64, 96, 64, 64)
            gravity = Gravity.CENTER_HORIZONTAL
        }

        // Header Title
        val titleView = TextView(this).apply {
            text = "MENSAJE DEL PROPIETARIO"
            textSize = 28f
            setTextColor(0xFF38BDF8.toInt()) // Light sky blue accent
            gravity = Gravity.CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(0, 24, 0, 24)
        }
        rootLayout.addView(titleView)

        // Message Body (Extra large)
        val bodyView = TextView(this).apply {
            text = messageText
            textSize = 28f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(16, 48, 16, 48)
            setTypeface(null, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1.0f
            )
        }
        rootLayout.addView(bodyView)

        // Contact Phone button if provided
        if (!contactPhone.isNullOrBlank()) {
            val callButton = Button(this).apply {
                text = "Llamar al propietario ($contactPhone)"
                setBackgroundColor(0xFF22C55E.toInt()) // Safe green
                setTextColor(0xFFFFFFFF.toInt())
                textSize = 16f
                setOnClickListener {
                    val dialIntent = Intent(Intent.ACTION_DIAL).apply {
                        data = Uri.parse("tel:$contactPhone")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(dialIntent)
                }
            }
            val callParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, 24)
            }
            rootLayout.addView(callButton, callParams)
        }

        // Understand / Dismiss Button
        val dismissButton = Button(this).apply {
            text = "Entendido"
            setBackgroundColor(0xFF334155.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            textSize = 16f
            setOnClickListener {
                finish()
            }
        }
        val dismissParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        rootLayout.addView(dismissButton, dismissParams)

        setContentView(rootLayout)
    }
}
