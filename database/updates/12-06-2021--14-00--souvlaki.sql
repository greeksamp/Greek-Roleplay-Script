CREATE TABLE `discord_message` ( 
    `discord_message` INT UNSIGNED NOT NULL AUTO_INCREMENT , 
    `message_content` VARCHAR(1024) NOT NULL , 
    `webhook_name` VARCHAR(32) NOT NULL , 
    PRIMARY KEY (`discord_message`)) ENGINE = InnoDB; 


ALTER TABLE `discord_message` ADD `added_on` INT UNSIGNED NOT NULL AFTER `webhook_name`, ADD `sent_on` INT UNSIGNED NULL DEFAULT NULL AFTER `added_on`; 