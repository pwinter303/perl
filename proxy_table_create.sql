SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;
USE `mydb` ;

-- ------------------------------------------------------
-- Table `mydb`.`proxy`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`proxy` (
  `proxyURL` VARCHAR(30) NOT NULL,
  `currPeriod_cummulative_good` INT NULL,
  `currPeriod_cummulative_bad` INT NULL,
  `currPeriod_bad` INT NULL,
  `currPeriod_good` INT NULL,
  `currPeriod_total_seconds` INT NULL,
  `prevPeriod_good` INT NULL,
  `prevPeriod_bad` INT NULL,
  PRIMARY KEY (`proxyURL`))
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
