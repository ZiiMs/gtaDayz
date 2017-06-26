-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               5.7.16-log - MySQL Community Server (GPL)
-- Server OS:                    Win64
-- HeidiSQL Version:             9.4.0.5125
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- Dumping database structure for GTADayz
DROP DATABASE IF EXISTS `GTADayz`;
CREATE DATABASE IF NOT EXISTS `GTADayz` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `GTADayz`;

-- Dumping structure for table GTADayz.accounts
DROP TABLE IF EXISTS `accounts`;
CREATE TABLE IF NOT EXISTS `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Username` varchar(50) NOT NULL,
  `Pass` varchar(130) NOT NULL,
  `Adminlevel` int(11) NOT NULL DEFAULT '0',
  `Skin` int(11) NOT NULL DEFAULT '12',
  `X` float NOT NULL DEFAULT '1536.61',
  `Y` float NOT NULL DEFAULT '-1691.2',
  `Z` float NOT NULL DEFAULT '13.3',
  `FacingAngle` float NOT NULL DEFAULT '78.0541',
  `Blood` int(11) NOT NULL DEFAULT '12000',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

-- Dumping data for table GTADayz.accounts: ~2 rows (approximately)
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
REPLACE INTO `accounts` (`id`, `Username`, `Pass`, `Adminlevel`, `Skin`, `X`, `Y`, `Z`, `FacingAngle`, `Blood`) VALUES
	(4, 'ZiiM', '1560FB5FDFD2614A5B255AA5557168D7D4A7E51BB19FBF4B10BC84BB506E8975446CECE52BA8262279546AAB3348065121C99DEDD25258AE602C11FF8E25836A', 9, 194, 1470.94, -1616.31, 14.139, 38.969, 4800),
	(5, 'Alex_T', '1560FB5FDFD2614A5B255AA5557168D7D4A7E51BB19FBF4B10BC84BB506E8975446CECE52BA8262279546AAB3348065121C99DEDD25258AE602C11FF8E25836A', 0, 12, 1534.23, -1615.37, 13.483, 190.115, 4800);
/*!40000 ALTER TABLE `accounts` ENABLE KEYS */;

-- Dumping structure for table GTADayz.lootspawns
DROP TABLE IF EXISTS `lootspawns`;
CREATE TABLE IF NOT EXISTS `lootspawns` (
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Dumping data for table GTADayz.lootspawns: ~0 rows (approximately)
/*!40000 ALTER TABLE `lootspawns` DISABLE KEYS */;
REPLACE INTO `lootspawns` (`X`, `Y`, `Z`) VALUES
	(1471.03, -1613.1, 14.039),
	(1510.32, -1636.65, 14.123),
	(1529.88, -1656.07, 14.037),
	(1535.9, -1670.41, 13.383),
	(1537.4, -1684.09, 13.547),
	(1529.23, -1688.67, 13.383);
/*!40000 ALTER TABLE `lootspawns` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
