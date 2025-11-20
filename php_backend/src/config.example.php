<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require_once 'vendor/autoload.php';

function createMailer(): PHPMailer
{
    $mail = new PHPMailer(true);

    //Server settings
    $mail->isSMTP();
    $mail->Host       = 'smtp.gmail.com'; // Or your SMTP server
    $mail->SMTPAuth   = true;
    $mail->Username   = 'your_email@example.com'; // Your SMTP username
    $mail->Password   = 'your_app_password';    // Your SMTP password or App Password
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = 587;

    //Set default sender
    $mail->setFrom('your_email@example.com', 'Supply Chain System');

    return $mail;
}
?>
