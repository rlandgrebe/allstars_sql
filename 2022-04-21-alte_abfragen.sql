/* Arbeitskosten und Stunden nach Mitarbeiterkategorie */
SELECT `name` AS Kategorie, SUM(Stunden) AS Stunden, SUM(Arbeitskosten) AS Arbeitskosten FROM (
	SELECT
	employee_category.id,
	employee_category.`name`,
	(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60) + (add_min / 60)) AS Stunden,
	(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60) + (add_min / 60)) * employee_category.cost_hour AS Arbeitskosten
	FROM WorkingTime
	INNER JOIN employee ON WorkingTime.employee = employee.id
	LEFT JOIN employee_category ON employee.category = employee_category.id
	WHERE WorkingTime.`begin` >= '2014-05-01 00:00:00' AND WorkingTime.`begin` < '2014-06-01 00:00:00'
) t1
GROUP BY id
ORDER BY `name`


/* Arbeitskosten nach Team */
SELECT SUM(Stunden) AS Stunden, SUM(Arbeitskosten) AS Arbeitskosten FROM (
	SELECT
	employee_category.id, employee_category.`name`,
		(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60) + (add_min / 60)) AS Stunden,
		(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60) + (add_min / 60)) * employee_category.cost_hour AS Arbeitskosten
	FROM employee_qualification
	INNER JOIN WorkingTime ON employee_qualification.employee = WorkingTime.employee
	INNER JOIN employee ON employee_qualification.employee = employee.id
	INNER JOIN employee_category ON employee.category = employee_category.id
	WHERE `level` = 20
) t1

/* Anzahl der Stunden nach Kunden */
SELECT `name` AS Kunde, SUM(Stunden) AS Nettostunden FROM (
	SELECT customer.id, customer.`name`, (TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden FROM customer
	INNER JOIN `event` ON customer.id = `event`.customer
	INNER JOIN appointment ON `event`.id = appointment.`event` AND `status` = "Assigned"
	INNER JOIN employee ON appointment.employee = employee.id
	INNER JOIN WorkingTime ON appointment.id = WorkingTime.appointment
	WHERE WorkingTime.`begin` >= '2014-01-01 00:00:00' AND WorkingTime.`begin` < '2015-01-01 00:00:00'
) t1
GROUP BY id
ORDER BY `name`
LIMIT 0, 250

/* Anzahl der Stunden nach Kunden (alle Kunden auflisten) */
SELECT customer.name AS Kunde, Nettostunden FROM customer
LEFT JOIN (
	SELECT id, SUM(Stunden) AS Nettostunden FROM (
		SELECT customer.id, customer.`name`, (TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden FROM customer
		INNER JOIN `event` ON customer.id = `event`.customer
		INNER JOIN appointment ON `event`.id = appointment.`event` AND `status` = "Assigned"
		INNER JOIN employee ON appointment.employee = employee.id
		INNER JOIN WorkingTime ON appointment.id = WorkingTime.appointment
		WHERE WorkingTime.`begin` >= '2015-01-01 00:00:00' AND WorkingTime.`begin` < '2015-02-01 00:00:00'
	) t1
	GROUP BY id
) tParent ON customer.id = tParent.id
WHERE customer.location = 1 OR customer.location IS NULL
ORDER BY customer.name
LIMIT 0, 500

/* Durchschnittliche Punktzahl je Kunde in 2014 */
SELECT customer.name AS Kunde, AVG(`index`) AS Punkteschnitt FROM `event`
INNER JOIN customer ON `event`.customer = customer.id
INNER JOIN appointment ON `event`.id = appointment.`event` AND `status` = "Assigned"
INNER JOIN employee_qualification ON appointment.employee = employee_qualification.employee
INNER JOIN qualification_index ON employee_qualification.`level` = qualification_index.id
WHERE employee_qualification.qualification = 20 AND `event`.`begin` >= '2014-01-01 00:00:00' AND `event`.`begin` < '2015-01-01 00:00:00'
GROUP BY customer.id
ORDER BY customer.name

/* Durchschnittliche Punktzahl je Kunde und Monat in 2014 */
SELECT `name`, Punkteschnitt FROM customer tblCustomer
LEFT JOIN (
	SELECT customer.id, customer.name AS Kunde, AVG(`index`) AS Punkteschnitt FROM `event`
	INNER JOIN customer ON `event`.customer = customer.id
	INNER JOIN appointment ON `event`.id = appointment.`event` AND `status` = "Assigned"
	INNER JOIN employee_qualification ON appointment.employee = employee_qualification.employee
	INNER JOIN qualification_index ON employee_qualification.`level` = qualification_index.id
	WHERE employee_qualification.qualification = 20 AND `event`.`begin` >= '2014-01-01 00:00:00' AND `event`.`begin` < '2015-01-01 00:00:00'
	GROUP BY customer.id
) t2 ON tblCustomer.id = t2.id
ORDER BY `name`
LIMIT 0, 300

/* Gelieferte Stunden je Kunde und Monat in 2014 */
SELECT `name`, Nettostunden FROM customer tblCustomer
LEFT JOIN (
	SELECT id, `name` AS Kunde, SUM(Stunden) AS Nettostunden FROM (
		SELECT customer.id, customer.`name`, (TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden FROM customer
		INNER JOIN `event` ON customer.id = `event`.customer
		INNER JOIN appointment ON `event`.id = appointment.`event` AND `status` = "Assigned"
		INNER JOIN employee ON appointment.employee = employee.id
		INNER JOIN WorkingTime ON appointment.id = WorkingTime.appointment
		WHERE WorkingTime.`begin` >= '2014-01-01 00:00:00' AND WorkingTime.`begin` < '2015-01-01 00:00:00'
	) t1
	GROUP BY id
) t2 ON tblCustomer.id = t2.id
ORDER BY `name`
LIMIT 0, 300

/* Mitarbeiterliste (Vorname, Nachname, Standort, Kategorie, Aktiv) für die Folgeabfrage */
SELECT first_name AS Vorname, last_name AS Nachname, location AS Standort, employee_category.name AS Mitarbeiterkategorie, active AS Aktiv FROM `employee`
LEFT JOIN employee_category ON employee.category = employee_category.id
LIMIT 0, 5000

/* Mitarbeiterstunden nach Monat (summiert; ohne Zusatz-Minuten, die nur der internen Abrechnung dienen) */
SELECT first_name, last_name, REPLACE(Stunden, '.', ',') AS Stunden FROM employee e1
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2015-01-01 00:00:00' AND WorkingTime.`begin` < '2015-02-01 00:00:00'
  GROUP BY employee.id
) t1 ON e1.id = t1.id
ORDER BY e1.id
LIMIT 0, 5000

/* Wie viele Arbeitsmonate hatten die einzelnen Mitarbeiter-IDs im Betrachtungszeitraum nach Standort */
SELECT employee, COUNT(*) AS anz FROM (
  SELECT employee
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE `begin` >= '2014-01-01 00:00:00' AND `begin` < '2016-05-01 00:00:00' AND (employee.location = 1 OR employee.location IS NULL)
  GROUP BY employee.id, YEAR(`begin`), MONTH(`begin`)
) s1
GROUP BY employee
LIMIT 0, 1000

/* Mitarbeiterliste eingeplanter Mitarbeiter in einem Zeitraum (für Events & Morr) */
SELECT first_name AS Vorname, last_name AS Nachname, customer.`name` AS Kunde, `event`.`name` AS Auftrag, `begin` AS Beginn, `end` AS Ende FROM appointment
INNER JOIN employee ON appointment.employee = employee.id
INNER JOIN `event` ON appointment.`event` = `event`.id
LEFT JOIN customer ON `event`.`customer` = customer.id
WHERE `begin` >= '2019-01-01 00:00:00' AND `begin` < '2019-02-01 00:00:00' AND `status` = "Assigned" AND `event`.`cancelled` = 0
ORDER BY last_name, first_name, `begin`, `end`
LIMIT 0, 10000

/* Mitarbeiterliste inkl. Kategorien für Arbeitszeiten ab einem bestimmten Datum */
SELECT first_name AS Vorname, last_name AS Nachname, employee_category.name AS Mitarbeiterkategorie, active AS Aktiv FROM `employee`
LEFT JOIN employee_category ON employee.category = employee_category.id
INNER JOIN appointment ON employee.id = appointment.employee
INNER JOIN `event` ON appointment.event = event.id
WHERE (employee.location = 1 OR employee.location IS NULL) AND `begin` >= '2015-01-01 00:00:00' AND cancelled = 0 AND appointment.status = 'Assigned'
GROUP BY employee.id
ORDER BY last_name, first_name
LIMIT 0, 5000

/* Mitarbeiter-Liste mit den Wish-Counts (einmalig und wöchentlich) (nur Mitarbeiter-IDs mit den Anzahlen der gezählten Elemente) */
SELECT employee.id, COUNT(employee_constraint.id) AS wishOnce, COUNT(employee_constraint_weekly.id) AS wishWeekly FROM `employee`
LEFT JOIN employee_constraint_weekly ON employee.id = employee_constraint_weekly.employee AND employee_constraint_weekly.constraint_type = 'Wish'
LEFT JOIN employee_constraint ON employee.id = employee_constraint.employee AND employee_constraint.constraint_type = 'Wish'
WHERE (employee.location = 1 OR employee.location IS NULL) AND active = 1
GROUP BY employee.id
LIMIT 0, 3000

/* Kundenliste inkl. Ansprechpartner und Nettostunden in einem Zeitraum */
SELECT customer.location AS Standort, customer.name AS Kunde, customer_contact.sex AS Anrede, first_name AS Vorname, last_name AS Nachname, email AS "E-Mail", position AS Position, tel_landline AS Festnetznummer, tel_mobile AS Mobilnummer, street AS "Straße", zip_code AS PLZ, city AS Ort, Nettostunden FROM customer
LEFT JOIN customer_contact ON customer.id = customer_contact.customer
LEFT JOIN customer_location ON customer.id = customer_location.customer
LEFT JOIN (
    SELECT id, SUM(Stunden) AS Nettostunden FROM (
        SELECT customer.id, customer.`name`, (TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden FROM customer
        INNER JOIN `event` ON customer.id = `event`.customer
        INNER JOIN appointment ON `event`.id = appointment.`event` AND `status` = "Assigned"
        INNER JOIN employee ON appointment.employee = employee.id
        INNER JOIN WorkingTime ON appointment.id = WorkingTime.appointment
        WHERE WorkingTime.`begin` >= '2017-01-01 00:00:00' AND WorkingTime.`begin` < '2017-10-24 00:00:00'
    ) t1
    GROUP BY id
) s1 ON customer.id = s1.id
WHERE customer.location = 1
ORDER BY customer.`name`
LIMIT 0, 5000


/* Alle Mitarbeiter, die ab einem bestimmten Datum bis jetzt gearbeitet haben mit aktuellstem PGS */
SELECT last_name, first_name, date_of_birth, s1.socialSecurityGroup, s1.`begin`, s1.`end` AS Austrittsdatum, s1.contractHours, s1.contractHoursBase FROM employee
INNER JOIN appointment ON employee.id = appointment.employee
INNER JOIN `event` ON appointment.event = event.id
LEFT JOIN (
	SELECT tEmployment.* FROM Employment tEmployment
	INNER JOIN
	    (
	    	SELECT employee, MAX(`begin`) AS maxBegin
			FROM Employment
			GROUP BY employee
		) tMaxBegin ON tEmployment.employee = tMaxBegin.employee AND tEmployment.`begin` = tMaxBegin.maxBegin
) s1 ON	employee.id = s1.employee
WHERE appointment.status = "Assigned" AND `event`.`begin` >= '2016-05-28 00:00:00' AND event.cancelled = 0 AND employee.location = 1
GROUP BY employee.id
ORDER BY last_name, first_name
LIMIT 0, 1000

/* Stunden pro Zeitraum für alle Aufträge nach Auftragsstatus */
SELECT status_type, SUM(ABS(TIME_TO_SEC(TIMEDIFF(`end`,`begin`))) * quantity / 3600) AS totalHours FROM `event`
WHERE `begin` >= '2017-09-01 00:00:00' AND `begin` < '2017-10-01 00:00:00' AND cancelled = 0 AND customer NOT IN (236, 42, 531, 112, 298, 400, 297, 370, 295, 299, 296) AND location = 1
GROUP BY status_type

/* Abfrage der Mitarbeitertermine für einen Kunden (idR im Rahmen einer Überprüfung beim Kunden) */
SELECT last_name AS Nachname, first_name AS Vorname, event.name AS Veranstaltung, begin as Beginn, end as Ende FROM appointment
INNER JOIN `event`  ON `appointment`.`event` = event.id
INNER JOIN employee ON appointment.employee = employee.id
WHERE `status` = "Assigned" AND event.customer = 452 AND `event`.`begin` > '2017-01-01 00:00:00'
ORDER BY last_name, first_name
LIMIT 0, 500

/* Arbeitszeiten und aktuell vereinbarte Stunden der Mitarbeiter für angegebene Monate */
SELECT first_name AS Vorname, last_name AS Nachname,
REPLACE(Stunden1, '.', ',') AS Sep17,
REPLACE(Stunden2, '.', ',') AS Okt17,
(CASE WHEN t3.contractHoursBase = "Weekly" THEN t3.contractHours * 4.348 ELSE t3.contractHours END) AS "Vereinbart per 01.09.2017"
FROM employee e1
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden1
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-09-01 00:00:00' AND WorkingTime.`begin` < '2017-10-01 00:00:00'
  GROUP BY employee.id
) t1 ON e1.id = t1.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden2
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-10-01 00:00:00' AND WorkingTime.`begin` < '2017-11-01 00:00:00'
  GROUP BY employee.id
) t2 ON e1.id = t2.id
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-09-01 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) t3 ON e1.id = t3.id 
WHERE e1.location = 1 AND (Stunden1 IS NOT NULL OR Stunden2 IS NOT NULL)
ORDER BY e1.last_name, e1.first_name
LIMIT 0, 5000

/* Kundenkontaktliste inkl. Adressen nach Standort */
SELECT customer.name AS Kunde, sex AS Anrede, first_name AS Vorname, last_name AS Nachname, position AS Position, email AS "E-Mail", tel_landline AS TelFestnetz, tel_mobile AS TelMobile, street AS "Straße", zip_code AS PLZ, city AS Ort
FROM customer_contact
INNER JOIN customer on customer_contact.customer = customer.id
LEFT JOIN customer_location ON customer.id = customer_location.customer AND is_main = 1
WHERE customer.location = 2
ORDER BY customer.name, last_name, first_name
LIMIT 0, 700

/* Aktuell gültige Lohnstufen der Mitarbeiter */
SELECT first_name AS Vorname, last_name AS Nachname, Gruppe, Stufe, hourlyWage AS Basislohn, hourlyBonus AS Zulage FROM employee
LEFT JOIN (
    SELECT wageGroup1.employee AS employee, wageGroup1.validFrom AS validFrom, MIN(wageGroup2.validFrom) AS validUntil, amount AS hourlyWage, bonus AS hourlyBonus, tblWageGroup.name AS Gruppe, wage.`level` AS Stufe
    FROM UMDEmployeeWageLevel wageGroup1
    INNER JOIN UMDWageLevel wage ON wageGroup1.wageLevel = wage.id
    INNER JOIN UMDWageGroup tblWageGroup ON wage.group = tblWageGroup.id
    LEFT JOIN UMDEmployeeWageLevel wageGroup2 ON wageGroup1.employee = wageGroup2.employee AND wageGroup1.id != wageGroup2.id AND wageGroup2.validFrom > wageGroup1.validFrom AND wageGroup2.cancellation = 0
    WHERE wageGroup1.cancellation = 0
    GROUP BY wageGroup1.id
) wage ON employee.id = wage.employee AND NOW() >= wage.validFrom AND (NOW() < wage.validUntil OR wage.validUntil IS NULL)
WHERE active = 1 AND location = 2
ORDER BY last_name, first_name
LIMIT 0, 2000

/* Mitarbeiterzahlen für die Abrechnung der Corteam-Beiträge */
/* Es wird die Anzahl der Mitarbeiter berechnet, die in einem Monat eingebucht waren */
SELECT employee
FROM appointment a
INNER JOIN event e ON a.event = e.id AND a.tenant = e.tenant
WHERE status = 'Assigned' AND begin >= '2021-05-01 00:00:00' AND begin < '2021-12-01 00:00:00' AND a.tenant = '2fc3e885-d5d7-4b79-b291-5320f866133c'
GROUP BY a.employee;
/* Spezialfall: VilaVita */
SELECT employee FROM appointment
INNER JOIN requirement_employee ON appointment.requirement = requirement_employee.id
INNER JOIN event ON requirement_employee.event = event.id
WHERE status = "Approved" AND event.begin >= "2021-04-01 00:00:00" AND event.begin < "2021-05-01 00:00:00"
GROUP BY appointment.employee;

/* Tatsächliche Arbeitszeiten pro Monat / PGS per Monatsletztem / Sollarbeitszeiten pro Monat in einer Jahresübersicht */
SELECT first_name AS Vorname, last_name AS Nachname,
REPLACE(Stunden1, '.', ',') AS Jan17,
REPLACE(Stunden2, '.', ',') AS Feb17,
REPLACE(Stunden3, '.', ',') AS Mar17,
REPLACE(Stunden4, '.', ',') AS Apr17,
REPLACE(Stunden5, '.', ',') AS Mai17,
REPLACE(Stunden6, '.', ',') AS Jun17,
REPLACE(Stunden7, '.', ',') AS Jul17,
REPLACE(Stunden8, '.', ',') AS Aug17,
REPLACE(Stunden9, '.', ',') AS Sep17,
REPLACE(Stunden10, '.', ',') AS Okt17,
REPLACE(Stunden11, '.', ',') AS Nov17,
REPLACE(Stunden12, '.', ',') AS Dez17,
s1.socialSecurityGroup AS PGS_Jan17,
s2.socialSecurityGroup AS PGS_Feb17,
s3.socialSecurityGroup AS PGS_Mar17,
s4.socialSecurityGroup AS PGS_Apr17,
s5.socialSecurityGroup AS PGS_Mai17,
s6.socialSecurityGroup AS PGS_Jun17,
s7.socialSecurityGroup AS PGS_Jul17,
s8.socialSecurityGroup AS PGS_Aug17,
s9.socialSecurityGroup AS PGS_Sep17,
s10.socialSecurityGroup AS PGS_Okt17,
s11.socialSecurityGroup AS PGS_Nov17,
s12.socialSecurityGroup AS PGS_Dez17,
REPLACE(CASE WHEN s1.contractHoursBase = "Weekly" THEN s1.contractHours * 4.34 ELSE s1.contractHours END, '.', ',') AS "Soll_Jan17",
REPLACE(CASE WHEN s2.contractHoursBase = "Weekly" THEN s2.contractHours * 4.34 ELSE s2.contractHours END, '.', ',') AS "Soll_Feb17",
REPLACE(CASE WHEN s3.contractHoursBase = "Weekly" THEN s3.contractHours * 4.34 ELSE s3.contractHours END, '.', ',') AS "Soll_Mar17",
REPLACE(CASE WHEN s4.contractHoursBase = "Weekly" THEN s4.contractHours * 4.34 ELSE s4.contractHours END, '.', ',') AS "Soll_Apr17",
REPLACE(CASE WHEN s5.contractHoursBase = "Weekly" THEN s5.contractHours * 4.34 ELSE s5.contractHours END, '.', ',') AS "Soll_Mai17",
REPLACE(CASE WHEN s6.contractHoursBase = "Weekly" THEN s6.contractHours * 4.34 ELSE s6.contractHours END, '.', ',') AS "Soll_Jun17",
REPLACE(CASE WHEN s7.contractHoursBase = "Weekly" THEN s7.contractHours * 4.34 ELSE s7.contractHours END, '.', ',') AS "Soll_Jul17",
REPLACE(CASE WHEN s8.contractHoursBase = "Weekly" THEN s8.contractHours * 4.34 ELSE s8.contractHours END, '.', ',') AS "Soll_Aug17",
REPLACE(CASE WHEN s9.contractHoursBase = "Weekly" THEN s9.contractHours * 4.34 ELSE s9.contractHours END, '.', ',') AS "Soll_Sep17",
REPLACE(CASE WHEN s10.contractHoursBase = "Weekly" THEN s10.contractHours * 4.34 ELSE s10.contractHours END, '.', ',') AS "Soll_Okt17",
REPLACE(CASE WHEN s11.contractHoursBase = "Weekly" THEN s11.contractHours * 4.34 ELSE s11.contractHours END, '.', ',') AS "Soll_Nov17",
REPLACE(CASE WHEN s12.contractHoursBase = "Weekly" THEN s12.contractHours * 4.34 ELSE s12.contractHours END, '.', ',') AS "Soll_Dez17"
FROM employee e1
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden1
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-01-01 00:00:00' AND WorkingTime.`begin` < '2017-02-01 00:00:00'
  GROUP BY employee.id
) t1 ON e1.id = t1.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden2
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-02-01 00:00:00' AND WorkingTime.`begin` < '2017-03-01 00:00:00'
  GROUP BY employee.id
) t2 ON e1.id = t2.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden3
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-03-01 00:00:00' AND WorkingTime.`begin` < '2017-04-01 00:00:00'
  GROUP BY employee.id
) t3 ON e1.id = t3.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden4
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-04-01 00:00:00' AND WorkingTime.`begin` < '2017-05-01 00:00:00'
  GROUP BY employee.id
) t4 ON e1.id = t4.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden5
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-05-01 00:00:00' AND WorkingTime.`begin` < '2017-06-01 00:00:00'
  GROUP BY employee.id
) t5 ON e1.id = t5.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden6
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-06-01 00:00:00' AND WorkingTime.`begin` < '2017-07-01 00:00:00'
  GROUP BY employee.id
) t6 ON e1.id = t6.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden7
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-07-01 00:00:00' AND WorkingTime.`begin` < '2017-08-01 00:00:00'
  GROUP BY employee.id
) t7 ON e1.id = t7.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden8
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-08-01 00:00:00' AND WorkingTime.`begin` < '2017-09-01 00:00:00'
  GROUP BY employee.id
) t8 ON e1.id = t8.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden9
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-09-01 00:00:00' AND WorkingTime.`begin` < '2017-10-01 00:00:00'
  GROUP BY employee.id
) t9 ON e1.id = t9.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden10
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-10-01 00:00:00' AND WorkingTime.`begin` < '2017-11-01 00:00:00'
  GROUP BY employee.id
) t10 ON e1.id = t10.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden11
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-11-01 00:00:00' AND WorkingTime.`begin` < '2017-12-01 00:00:00'
  GROUP BY employee.id
) t11 ON e1.id = t11.id
LEFT JOIN (
  SELECT employee.id, SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden12
  FROM WorkingTime
  INNER JOIN employee ON WorkingTime.employee = employee.id
  WHERE WorkingTime.`begin` >= '2017-12-01 00:00:00' AND WorkingTime.`begin` < '2018-01-01 00:00:00'
  GROUP BY employee.id
) t12 ON e1.id = t12.id
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-01-31 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s1 ON e1.id = s1.id
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-02-28 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s2 ON e1.id = s2.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-03-31 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s3 ON e1.id = s3.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-04-30 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s4 ON e1.id = s4.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-05-31 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s5 ON e1.id = s5.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-06-30 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s6 ON e1.id = s6.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-07-31 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s7 ON e1.id = s7.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-08-31 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s8 ON e1.id = s8.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-09-30 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s9 ON e1.id = s9.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-10-31 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s10 ON e1.id = s10.id 
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-11-30 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s11 ON e1.id = s11.id
LEFT JOIN (
    SELECT e1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment e1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2017-12-31 00:00:00'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1.`begin` = e2.maxBegin
) s12 ON e1.id = s12.id 
WHERE e1.location = 1 AND (Stunden1 IS NOT NULL OR Stunden2 IS NOT NULL OR Stunden3 IS NOT NULL  OR Stunden4 IS NOT NULL  OR Stunden5 IS NOT NULL  OR Stunden6 IS NOT NULL  OR Stunden7 IS NOT NULL  OR Stunden8 IS NOT NULL  OR Stunden9 IS NOT NULL  OR Stunden10 IS NOT NULL  OR Stunden11 IS NOT NULL  OR Stunden12 IS NOT NULL )
ORDER BY e1.last_name, e1.first_name
LIMIT 0, 500

/* Eingeplante Arbeitszeiten für einen bestimmten Monat / PGS per Monatsletztem / Sollarbeitszeiten pro Monat in einer Jahresübersicht */
SELECT first_name AS Vorname, last_name AS Nachname, e1.location AS Standort,
REPLACE(Stunden1, '.', ',') AS Ist_Mai20,
REPLACE(CASE WHEN s1.contractHoursBase = "Weekly" THEN s1.contractHours * 4.34 ELSE s1.contractHours END, '.', ',') AS "Soll_Mai20",
s1.socialSecurityGroup AS PGS_Mai20
FROM employee e1
LEFT JOIN (
    SELECT employee AS id, SUM(TIME_TO_SEC(TIMEDIFF(`event`.`end`, `event`.`begin`)) / 3600) AS Stunden1
    FROM appointment
    INNER JOIN event ON appointment.event = event.id
    WHERE event.cancelled = 0 AND appointment.status = 'Assigned' AND event.`begin` >= '2020-05-01 00:00:00' AND event.`begin` < '2020-06-01 00:00:00'
    GROUP BY employee
) t1 ON e1.id = t1.id
LEFT JOIN (
    SELECT emp1.employee AS id, contractHours, contractHoursBase, socialSecurityGroup FROM Employment emp1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2020-05-31 00:00:00'
        GROUP BY employee
    ) AS emp2 ON emp1.employee = emp2.employee AND emp1.`begin` = emp2.maxBegin
) s1 ON e1.id = s1.id
WHERE e1.location IN (1) AND Stunden1 IS NOT NULL
ORDER BY e1.last_name, e1.first_name
LIMIT 0, 1000

/* Einzelauftragsliste für eine Kundenliste in einem Zeitraum mit MA-Ist/MA-Soll/Punkte-Ist/Punkte-Soll für Qualifikation 20/Veranstaltungsart */
SELECT customer.name AS Kunde, `event`.name AS Auftrag, event_type.name AS "VA-Art", `event`.`begin` AS Beginn, `event`.`end` AS Ende, `event`.quantity AS MA_Soll, COUNT(appointment.id) AS MA_Ist, AVG(maxIndex) AS Punkte_Ist, requirement_avgpoint.points AS Punkte_Soll FROM `event`
LEFT JOIN appointment ON `event`.id = appointment.`event` AND appointment.`status` = "Assigned"
LEFT JOIN (
    SELECT employee.id AS employee, MAX(`index`) AS maxIndex FROM employee
    INNER JOIN employee_qualification ON employee.id = employee_qualification.employee
    INNER JOIN qualification_index ON employee_qualification.`level` = qualification_index.id
    WHERE employee_qualification.qualification = 20
    GROUP BY employee.id
) s1 ON appointment.employee = s1.employee
LEFT JOIN customer ON `event`.customer = customer.id
LEFT JOIN event_type ON `event`.event_type = event_type.id
LEFT JOIN requirement_avgpoint ON `event`.id = requirement_avgpoint.`event` AND `qualification` = 20 AND operator IN ('GreaterEqual', 'Greater', 'Equal')
WHERE `event`.customer IN (357, 40, 240, 185) /* Kundenliste ist anzupassen */ AND cancelled = 0 AND `begin` >= '2016-01-01 00:00:00' AND `begin` < '2017-01-01 00:00:00' AND status_type = "Event"
GROUP BY `event`.id
ORDER BY customer.`name`, `begin` ASC, `end` ASC
LIMIT 0, 500 /* Limit ist anzupassen */

/* Abfrage, wo Stundenlöhne für erfasste Arbeitszeiten fehlen (ab einem bestimmten Datum) */
SELECT employee.location AS Standort, first_name AS Vorname, last_name AS Nachname, MIN(`begin`) AS Beginn, MAX(`end`) AS Ende, hourlyWage FROM WorkingTime
INNER JOIN employee ON WorkingTime.employee = employee.id
LEFT JOIN (
    SELECT wageGroup1.mitarbeiter AS employee, wageGroup1.gueltigab AS validFrom, MIN(wageGroup2.gueltigab) AS validUntil, betrag AS hourlyWage
    FROM u_std_lohnstufe_ma wageGroup1
    INNER JOIN u_std_lohnstufe wage ON wageGroup1.lohnstufe = wage.id
    LEFT JOIN u_std_lohnstufe_ma wageGroup2 ON wageGroup1.mitarbeiter = wageGroup2.mitarbeiter AND wageGroup1.id != wageGroup2.id AND wageGroup2.gueltigab > wageGroup1.gueltigab AND wageGroup2.storno = 0
    WHERE wageGroup1.storno = 0
    GROUP BY wageGroup1.id
) wage ON employee.id = wage.employee AND WorkingTime.`begin` >= wage.validFrom AND (WorkingTime.`begin` < wage.validUntil OR wage.validUntil IS NULL)
WHERE `begin` >= '2016-01-01 00:00:00' AND hourlyWage IS NULL
GROUP BY employee.id;

/* Einzelauflistung, wo Lohnkosten entstanden sind */
SELECT
first_name AS Vorname,
last_name AS Nachname,
Employment.socialSecurityGroup AS "Personengruppe",
customer.`name` AS Kunde,
`event`.`name` AS Auftrag,
WorkingTime.`begin` AS Beginn,
WorkingTime.`end` AS Ende,
breakMins AS "Pause (Minuten)",
CASE WHEN wage.hourlyWage IS NOT NULL THEN (TIME_TO_SEC(TIMEDIFF(WorkingTime.`end`, WorkingTime.`begin`)) / 60 - breakMins + addMins) / 60 ELSE NULL END AS Arbeitsstunden,
addMins AS "Zeitzuschlag (Minuten)",
wage.hourlyWage AS Stundenlohn,
moneyAdd AS "Nettobezug",
moneyAddHourly "Stundenzuschlag",
costFactor AS Kostenfaktor,
costFactorFlatTax AS "Kostenfaktor (Pauschalversteuerung)",
Employment.flatTax AS "Pauschalversteuerung",
((TIME_TO_SEC(TIMEDIFF(WorkingTime.`end`, WorkingTime.`begin`)) / 60 - breakMins + addMins) / 60) * (wage.hourlyWage + moneyAddHourly) AS Bruttobezüge,
(CASE Employment.flatTax
    WHEN 0 THEN ((TIME_TO_SEC(TIMEDIFF(WorkingTime.`end`, WorkingTime.`begin`)) / 60 - breakMins + addMins) / 60) * (wage.hourlyWage + moneyAddHourly) * costFactor
    WHEN 1 THEN ((TIME_TO_SEC(TIMEDIFF(WorkingTime.`end`, WorkingTime.`begin`)) / 60 - breakMins + addMins) / 60) * (wage.hourlyWage + moneyAddHourly) * costFactorFlatTax
    ELSE ((TIME_TO_SEC(TIMEDIFF(WorkingTime.`end`, WorkingTime.`begin`)) / 60 - breakMins + addMins) / 60) * (wage.hourlyWage + moneyAddHourly) END) AS Bruttolohnkosten
FROM WorkingTime
INNER JOIN employee ON WorkingTime.employee = employee.id
LEFT JOIN appointment ON WorkingTime.appointment = appointment.id
LEFT JOIN `event` ON appointment.`event` = `event`.id
LEFT JOIN customer ON `event`.customer = customer.id
LEFT JOIN Employment ON WorkingTime.employee = Employment.employee AND WorkingTime.`begin` >= Employment.`begin` AND (Employment.`end` IS NULL OR WorkingTime.`end` <= Employment.`end`)
LEFT JOIN UMDSocialSecurityGroup ON Employment.socialSecurityGroup = UMDSocialSecurityGroup.groupKey
LEFT JOIN (
    SELECT wageGroup1.mitarbeiter AS employee, wageGroup1.gueltigab AS validFrom, MIN(wageGroup2.gueltigab) AS validUntil, betrag AS hourlyWage
    FROM u_std_lohnstufe_ma wageGroup1
    INNER JOIN u_std_lohnstufe wage ON wageGroup1.lohnstufe = wage.id
    LEFT JOIN u_std_lohnstufe_ma wageGroup2 ON wageGroup1.mitarbeiter = wageGroup2.mitarbeiter AND wageGroup1.id != wageGroup2.id AND wageGroup2.gueltigab > wageGroup1.gueltigab AND wageGroup2.storno = 0
    WHERE wageGroup1.storno = 0
    GROUP BY wageGroup1.id
) wage ON employee.id = wage.employee AND WorkingTime.`begin` >= wage.validFrom AND (WorkingTime.`begin` < wage.validUntil OR wage.validUntil IS NULL)
WHERE employee.location = 1 AND `WorkingTime`.`begin` >= '2017-01-01 00:00:00' AND `WorkingTime`.`begin` < '2017-02-01 00:00:00' AND ((WorkingTime.costCenter IS NOT NULL AND WorkingTime.costCenter = 1) OR (WorkingTime.costCenter IS NULL AND employee.costCenter = 1))
ORDER BY last_name, first_name, WorkingTime.`begin`, WorkingTime.`end`
LIMIT 0, 6000

/* Statistische Abfrage der Mitarbeiterbewertungen */
SELECT
    last_name AS Nachname,
    first_name AS Vorname,
    countTotal AS "Einsätze",
    (sumAvgRating / scoreCount) AS Score,
    countGood AS "Bewertung: Gut",
    countNeutral AS "Bewertung: Neutral",
    countBad AS "Bewertung: Schlecht",
    internalPoints AS "Punkte Intern",
    likes AS "Anzahl Kundenwünsche",
    dislikes AS "Anzahl Kundensperren",
    employeeLikes AS "Anzahl Mitarbeiterwünsche",
    employeeDislikes AS "Anzahl Mitarbeitersperren",
    qualification AS Qualifikation,
    IF(t9.contractHoursBase = "Monthly", t9.contractHours, t9.contractHours * 4.348) AS "Vertragsstunden (p.M.)",
    netHoursPerMonth AS "Stunden gearbeitet (p.M.)",
    socialSecurityGroup AS "Beschäftigungsart"
FROM employee
LEFT JOIN (
    SELECT employee, COUNT(*) AS countTotal FROM appointment WHERE `status` = "Assigned" GROUP BY employee
) AS t1 ON employee.id = t1.employee
LEFT JOIN (
    SELECT appointment.employee, COUNT(*) AS countNeutral FROM appointment
    LEFT JOIN rating ON appointment.id = rating.appointment
    WHERE appointment.`status` = "Assigned" AND rating.id IS NULL
    GROUP BY appointment.employee
) AS t2 ON employee.id = t2.employee
LEFT JOIN (
    SELECT employee, COUNT(IF(`like` = 1, rating.id, NULL)) AS countGood, COUNT(IF(`like` = 0, rating.id, NULL)) AS countBad
    FROM rating
    GROUP BY employee
) AS t3 ON employee.id = t3.employee
LEFT JOIN (
    SELECT employee, COUNT(avgRating) AS scoreCount, SUM(avgRating) AS sumAvgRating FROM (
        SELECT employee, AVG(`like`) AS avgRating
        FROM `rating`
        GROUP BY appointment
    ) AS s1
    GROUP BY employee
) AS t4 ON employee.id = t4.employee
LEFT JOIN (
    SELECT employee, SUM(CAST((weight * rowCount) AS SIGNED) * isPositive) AS internalPoints FROM (
        SELECT employee, IF(is_positive = 1, 1, -1) AS isPositive, weight, COUNT(DISTINCT appointment) AS rowCount FROM employee_rating
        INNER JOIN employee_rating_detail ON employee_rating.id = employee_rating_detail.parent
        INNER JOIN employee_rating_attribute ON employee_rating_detail.attribute = employee_rating_attribute.id
        GROUP BY employee, employee_rating_attribute.id
    ) AS s2
    GROUP BY employee
) AS t5 ON employee.id = t5.employee
LEFT JOIN (
    SELECT employee, COUNT(IF(customer_like = 1, id, NULL)) AS likes, COUNT(IF(customer_like = 0, id, NULL)) AS dislikes
    FROM employee_like
    GROUP BY employee
) AS t6 ON employee.id = t6.employee
LEFT JOIN (
    SELECT employee, COUNT(IF(`like` = 1, id, NULL)) AS employeeLikes, COUNT(IF(`like` = 0, id, NULL)) AS employeeDislikes
    FROM employee_employee_like
    GROUP BY employee
) AS t7 ON employee.id = t7.employee
LEFT JOIN (
    SELECT * FROM (
        SELECT employee, `name` AS qualification FROM employee_qualification
        INNER JOIN qualification_index ON employee_qualification.level = qualification_index.id
        WHERE employee_qualification.qualification = 20
        ORDER BY `index` DESC
    ) AS s3
    GROUP BY employee
) AS t8 ON employee.id = t8.employee
LEFT JOIN (
    SELECT Employment.employee, Employment.begin, contractHours, contractHoursBase, socialSecurityGroup,
        SUM(TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60) + (addMins / 60)) / (DATEDIFF(NOW(), Employment.`begin`) / 30.4167) AS netHoursPerMonth
    FROM Employment
    LEFT JOIN WorkingTime ON Employment.employee = WorkingTime.employee AND WorkingTime.`begin` >= Employment.`begin` AND (Employment.`end` IS NULL OR WorkingTime.`begin` < Employment.`end`)
    WHERE Employment.`begin` <= NOW() AND (Employment.`end` IS NULL OR Employment.`end` > NOW())
    GROUP BY Employment.employee
) AS t9 ON employee.id = t9.employee
WHERE active = 1 AND location = 1;

/* Anteil der erfassten Stunden nach Tageszeit */ 
SELECT COUNT(*)
FROM work_time
WHERE (
	DATE(`begin`) = DATE(`end`) AND TIME(`end`) > '22:00:00' AND TIME(`begin`) < '23:00:00'
) OR (
	DATE(`begin`) < DATE(`end`) AND (TIME(`end`) > '22:00:00' OR TIME(`begin`) <= '22:00:00')
)

/* Alle Mitarbeiter, die seit einem bestimmten Datum eine Schulung absolviert haben, aber außerhalb derer noch gearbeitet haben */
/* Campus-Kunden-IDs: 112,298,400,297,370,295,299,296 */
SELECT employee.first_name AS Vorname, employee.last_name AS Nachname FROM (
    SELECT employee FROM appointment
    INNER JOIN event ON appointment.event = event.id
    INNER JOIN employee ON appointment.employee = employee.id
    WHERE status = "Assigned" AND event.customer IN (112,298,400,297,370,295,299,296) AND begin > "2016-01-01 00:00:00" AND employee.location = 2
    GROUP BY appointment.employee
) s1
INNER JOIN employee ON s1.employee = employee.id
LEFT JOIN (
    SELECT employee FROM appointment
    INNER JOIN event ON appointment.event = event.id
    INNER JOIN employee ON appointment.employee = employee.id
    WHERE status = "Assigned" AND event.customer NOT IN (112,298,400,297,370,295,299,296) AND begin > "2016-01-01 00:00:00" AND employee.location = 2
    GROUP BY appointment.employee
) s2 ON s1.employee = s2.employee
WHERE s2.employee IS NULL
ORDER BY last_name, first_name
LIMIT 0, 100;

/* Anzahl aller Arbeitsmonate (Monate, in denen gearbeitet wurde) und Ersteintrittsdatum der derzeit aktiven Mitarbeiter */
SELECT first_name AS Vorname, last_name AS Nachname, COUNT(*) AS Arbeitsmonate, employment_date AS Ersteintrittsdatum FROM (
SELECT employee.id, first_name, last_name, employment_date FROM employee
LEFT JOIN appointment ON employee.id = appointment.employee AND appointment.status = "Assigned"
LEFT JOIN event ON appointment.event = event.id
WHERE active = 1 AND begin <= NOW() AND employee.location = 1
GROUP BY employee.id, YEAR(begin), MONTH(begin)
) s1
GROUP BY s1.id
ORDER BY Arbeitsmonate DESC

/* Anzahl der aktiven Mitarbeiter eines Standorts nach Monaten */
SELECT year AS Jahr, month as Monat, COUNT(*) AS AktiveMAAnzahl FROM (
    SELECT YEAR(`begin`) AS year, MONTH(`begin`) AS month, employee FROM appointment
    INNER JOIN employee ON appointment.employee = employee.id
    INNER JOIN event ON appointment.event = event.id
    WHERE status = "Assigned" AND employee.location = 2 AND `begin` >= '2017-08-01 00:00:00' AND `begin` < '2018-09-01 00:00:00'
    GROUP BY employee, YEAR(`begin`), MONTH(`begin`)
) s1
GROUP BY year, month

/* Stände der Arbeitszeitkonten zum Monatsende für Mitarbeiter eines Standorts */
SELECT sq0.datevEmployeeNumber AS datevId,
first_name AS Vorname,
last_name AS Nachname,
(sq1.amountMinutes / 60) AS Jan20,
(sq2.amountMinutes / 60) AS Feb20,
(sq3.amountMinutes / 60) AS Mar20,
(sq4.amountMinutes / 60) AS Apr20,
(sq5.amountMinutes / 60) AS Mai20,
(sq6.amountMinutes / 60) AS Jun20,
(sq7.amountMinutes / 60) AS Jul20,
(sq8.amountMinutes / 60) AS Aug20,
(sq9.amountMinutes / 60) AS Sep20,
(sq10.amountMinutes / 60) AS Okt20,
(sq11.amountMinutes / 60) AS Nov20,
(sq12.amountMinutes / 60) AS Dez20,
(sq13.amountMinutes / 60) AS Jan21
FROM employee
LEFT JOIN (
    SELECT Employment.employee, Employment.datevEmployeeNumber FROM Employment
    INNER JOIN (
        SELECT employee, MAX(`begin`) as maxBegin
        FROM `Employment`
        GROUP BY employee
    ) ssq1 ON Employment.employee = ssq1.employee AND Employment.begin = ssq1.maxBegin
) sq0 ON employee.id = sq0.employee
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq1 ON employee.id = sq1.employee AND sq1.fromDate < '2020-02-01 00:00:00' AND (sq1.toDate IS NULL OR sq1.toDate >= '2020-02-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq2 ON employee.id = sq2.employee AND sq2.fromDate < '2020-03-01 00:00:00' AND (sq2.toDate IS NULL OR sq2.toDate >= '2020-03-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq3 ON employee.id = sq3.employee AND sq3.fromDate < '2020-04-01 00:00:00' AND (sq3.toDate IS NULL OR sq3.toDate >= '2020-04-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq4 ON employee.id = sq4.employee AND sq4.fromDate < '2020-05-01 00:00:00' AND (sq4.toDate IS NULL OR sq4.toDate >= '2020-05-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq5 ON employee.id = sq5.employee AND sq5.fromDate < '2020-06-01 00:00:00' AND (sq5.toDate IS NULL OR sq5.toDate >= '2020-06-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq6 ON employee.id = sq6.employee AND sq6.fromDate < '2020-07-01 00:00:00' AND (sq6.toDate IS NULL OR sq6.toDate >= '2020-07-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq7 ON employee.id = sq7.employee AND sq7.fromDate < '2020-08-01 00:00:00' AND (sq7.toDate IS NULL OR sq7.toDate >= '2020-08-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq8 ON employee.id = sq8.employee AND sq8.fromDate < '2020-09-01 00:00:00' AND (sq8.toDate IS NULL OR sq8.toDate >= '2020-09-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq9 ON employee.id = sq9.employee AND sq9.fromDate < '2020-10-01 00:00:00' AND (sq9.toDate IS NULL OR sq9.toDate >= '2020-10-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq10 ON employee.id = sq10.employee AND sq10.fromDate < '2020-11-01 00:00:00' AND (sq10.toDate IS NULL OR sq10.toDate >= '2020-11-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq11 ON employee.id = sq11.employee AND sq11.fromDate < '2020-12-01 00:00:00' AND (sq11.toDate IS NULL OR sq11.toDate >= '2020-12-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq12 ON employee.id = sq12.employee AND sq12.fromDate < '2021-01-01 00:00:00' AND (sq12.toDate IS NULL OR sq12.toDate >= '2021-01-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountMinutes FROM UIDWorkTimeAccount tblFrom
    LEFT JOIN UIDWorkTimeAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq13 ON employee.id = sq13.employee AND sq13.fromDate < '2021-02-01 00:00:00' AND (sq13.toDate IS NULL OR sq13.toDate >= '2021-02-01 00:00:00')
WHERE employee.location = 2
HAVING
(
Jan20 IS NOT NULL
OR Feb20 IS NOT NULL
OR Mar20 IS NOT NULL
OR Apr20 IS NOT NULL
OR Mai20 IS NOT NULL
OR Jun20 IS NOT NULL
OR Jul20 IS NOT NULL
OR Aug20 IS NOT NULL
OR Sep20 IS NOT NULL
OR Okt20 IS NOT NULL
OR Nov20 IS NOT NULL
OR Dez20 IS NOT NULL
OR Jan21 IS NOT NULL
)
ORDER BY last_name, first_name INTO OUTFILE '/tmp/ffm.csv' FIELDS TERMINATED BY ';' ENCLOSED BY '"' LINES TERMINATED BY '\r\n';

/* Stände der Urlaubskonten zum Monatsende für Mitarbeiter mehrerer Standorte */
SELECT sq0.datevEmployeeNumber AS datevId,
first_name AS Vorname,
last_name AS Nachname,
(sq1.amountDays) AS Jan19,
(sq2.amountDays) AS Feb19,
(sq3.amountDays) AS Mar19,
(sq4.amountDays) AS Apr19,
(sq5.amountDays) AS Mai19,
(sq6.amountDays) AS Jun19,
(sq7.amountDays) AS Jul19,
(sq8.amountDays) AS Aug19,
(sq9.amountDays) AS Sep19,
(sq10.amountDays) AS Okt19,
(sq11.amountDays) AS Nov19,
(sq12.amountDays) AS Dez19
FROM employee
LEFT JOIN (
    SELECT Employment.employee, Employment.datevEmployeeNumber FROM Employment
    INNER JOIN (
        SELECT employee, MAX(`begin`) as maxBegin
        FROM `Employment`
        GROUP BY employee
    ) ssq1 ON Employment.employee = ssq1.employee AND Employment.begin = ssq1.maxBegin
) sq0 ON employee.id = sq0.employee
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq1 ON employee.id = sq1.employee AND sq1.fromDate < '2019-02-01 00:00:00' AND (sq1.toDate IS NULL OR sq1.toDate >= '2019-02-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq2 ON employee.id = sq2.employee AND sq2.fromDate < '2019-03-01 00:00:00' AND (sq2.toDate IS NULL OR sq2.toDate >= '2019-03-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq3 ON employee.id = sq3.employee AND sq3.fromDate < '2019-04-01 00:00:00' AND (sq3.toDate IS NULL OR sq3.toDate >= '2019-04-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq4 ON employee.id = sq4.employee AND sq4.fromDate < '2019-05-01 00:00:00' AND (sq4.toDate IS NULL OR sq4.toDate >= '2019-05-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq5 ON employee.id = sq5.employee AND sq5.fromDate < '2019-06-01 00:00:00' AND (sq5.toDate IS NULL OR sq5.toDate >= '2019-06-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq6 ON employee.id = sq6.employee AND sq6.fromDate < '2019-07-01 00:00:00' AND (sq6.toDate IS NULL OR sq6.toDate >= '2019-07-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq7 ON employee.id = sq7.employee AND sq7.fromDate < '2019-08-01 00:00:00' AND (sq7.toDate IS NULL OR sq7.toDate >= '2019-08-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq8 ON employee.id = sq8.employee AND sq8.fromDate < '2019-09-01 00:00:00' AND (sq8.toDate IS NULL OR sq8.toDate >= '2019-09-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq9 ON employee.id = sq9.employee AND sq9.fromDate < '2019-10-01 00:00:00' AND (sq9.toDate IS NULL OR sq9.toDate >= '2019-10-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq10 ON employee.id = sq10.employee AND sq10.fromDate < '2019-11-01 00:00:00' AND (sq10.toDate IS NULL OR sq10.toDate >= '2019-11-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq11 ON employee.id = sq11.employee AND sq11.fromDate < '2019-12-01 00:00:00' AND (sq11.toDate IS NULL OR sq11.toDate >= '2019-12-01 00:00:00')
LEFT JOIN (
    SELECT tblFrom.employee, tblFrom.fromDate, MIN(tblTo.fromDate) AS toDate, tblFrom.amountDays FROM UIDVacationAccount tblFrom
    LEFT JOIN UIDVacationAccount tblTo ON tblFrom.employee = tblTo.employee AND tblFrom.id != tblTo.id AND tblTo.fromDate > tblFrom.fromDate
    GROUP BY tblFrom.id
) sq12 ON employee.id = sq12.employee AND sq12.fromDate < '2020-01-01 00:00:00' AND (sq12.toDate IS NULL OR sq12.toDate >= '2020-01-01 00:00:00')
WHERE employee.location IN(1, 3, 4, 5)
HAVING
(
Jan19 IS NOT NULL
OR Feb19 IS NOT NULL
OR Mar19 IS NOT NULL
OR Apr19 IS NOT NULL
OR Mai19 IS NOT NULL
OR Jun19 IS NOT NULL
OR Jul19 IS NOT NULL
OR Aug19 IS NOT NULL
OR Sep19 IS NOT NULL
OR Okt19 IS NOT NULL
OR Nov19 IS NOT NULL
OR Dez19 IS NOT NULL
)
ORDER BY last_name, first_name INTO OUTFILE '/var/lib/mysql-files/ks.csv' FIELDS TERMINATED BY ';' ENCLOSED BY '"' LINES TERMINATED BY '\r\n';

/* E-Mail-Adressen aller Kunden, die ab einem bestimmten Datum einen Auftrag hatten */
SET group_concat_max_len = 10000000000;
SELECT GROUP_CONCAT(DISTINCT email) FROM `event`
INNER JOIN customer ON `event`.`customer` = customer.id
INNER JOIN customer_contact ON customer.id = customer_contact.customer
WHERE `begin` >= '2018-01-01 00:00:00' AND customer.location IN (1, 3, 4, 5) AND email <> ""
LIMIT 0, 10000;

/* E-Mail-Adressen aller Standardempfänger, die ab einem bestimmten Datum einen Auftrag hatten / inkl. Standardeinschränkung / ohne Service-Allstars-Adressen */
SELECT DISTINCT customer.name, customer_contact.email
FROM customer
INNER JOIN event ON customer.id = event.customer
LEFT JOIN customer_contact ON customer.id = customer_contact.customer AND customer_contact.receiveDocs = 1 AND customer_contact.email NOT LIKE "%service-allstars.de%"
WHERE begin >= '2019-01-01 00:00:00' AND cancelled = 0 AND customer.location NOT IN (2);


/* Rangliste aktiver Mitarbeiter eines Standorts nach Punkten in der internen Bewertung */
SELECT id, first_name AS Vorname, last_name AS Nachname, SUM(points) AS Punkte
FROM employee
INNER JOIN (
    SELECT employee, IF(is_positive = 1, weight, -weight) AS points FROM employee_rating er
    INNER JOIN employee_rating_detail erd ON er.id = erd.parent
    INNER JOIN employee_rating_attribute era ON erd.attribute = era.id
    GROUP BY er.appointment, era.id
) subPoints ON id = subPoints.employee
WHERE employee.location = 1 AND employee.active = 1
GROUP BY id
ORDER BY Punkte DESC

/* Wie lange sind die Mitarbeiter geblieben und wie viel haben sie gearbeitet? */
SELECT tblFirst.employee, first_name, last_name, firstWorkday, lastWorkday, numJobs FROM (
    SELECT employee, MIN(`begin`) AS firstWorkday
    FROM appointment
    INNER JOIN `event` ON appointment.`event` = `event`.id
    INNER JOIN employee ON appointment.employee = employee.id
    WHERE `status` = 'Assigned' AND employee.location = 2
    GROUP BY employee
    HAVING firstWorkday >= '2018-04-01 00:00:00'
) tblFirst
INNER JOIN employee ON tblFirst.employee = employee.id
INNER JOIN (
    SELECT employee, MAX(`begin`) AS lastWorkday
    FROM appointment
    INNER JOIN `event` ON appointment.`event` = `event`.id
    INNER JOIN employee ON appointment.employee = employee.id
    WHERE `status` = 'Assigned' AND employee.location = 2
    GROUP BY employee
) tblLast ON tblFirst.employee = tblLast.employee
LEFT JOIN (
    SELECT employee, COUNT(*) AS numJobs
    FROM appointment
    INNER JOIN `event` ON appointment.`event` = `event`.id
    INNER JOIN employee ON appointment.employee = employee.id
    WHERE `status` = 'Assigned' AND employee.location = 2 AND `begin` > '2018-04-01 00:00:00'
    GROUP BY employee
) tblJobs ON tblFirst.employee = tblJobs.employee
ORDER BY firstWorkday, lastWorkday, numJobs

/* Wann war der letzte Job der Mitarbeiter eines Standorts? */
SELECT first_name AS Vorname, last_name AS Nachname, MAX(begin) AS "Letzter Job", active AS Aktiv FROM employee
INNER JOIN appointment ON employee.id = appointment.employee AND appointment.status = "Assigned"
INNER JOIN event ON appointment.event = event.id
WHERE employee.location = 2 AND employee.active = 1
GROUP BY employee.id
ORDER BY MAX(begin)
LIMIT 0, 2000

/* Mitarbeiter eines Standortes mit Qualifikation, Eintrittsdatum und Lohnentwicklung */
SELECT first_name AS Vorname, last_name AS Nachname, employment_date AS Ersteintrittsdatum, qualification AS "Qualifikation", validFrom AS "Lohn ab", amount AS "Basislohn", bonus AS "Zulage", (amount + bonus) AS "Gesamt"
FROM employee
LEFT JOIN (
    SELECT * FROM (
        SELECT employee, `name` AS qualification FROM employee_qualification
        INNER JOIN qualification_index ON employee_qualification.level = qualification_index.id
        WHERE employee_qualification.qualification = 103
        ORDER BY `index` DESC
    ) AS s3
    GROUP BY employee
) AS tblQualification ON employee.id = tblQualification.employee
LEFT JOIN UMDEmployeeWageLevel employeeWageLevel ON employee.id = employeeWageLevel.employee
INNER JOIN UMDWageLevel wageLevel ON employeeWageLevel.wageLevel = wageLevel.id
WHERE employee.location = 1 AND employee.active = 1
ORDER BY last_name, first_name, validFrom ASC
LIMIT 0, 5000;

/* Alle von der Zeitumstellung betroffenen Arbeitszeiten filtern */
select customer.name AS Kunde, event.name AS VA, WorkingTime.begin AS Beginn, WorkingTime.end AS Ende, breakMins AS Pause, travelMins AS Reisezeit, employee.first_name AS Vorname, employee.last_name AS Nachname
from WorkingTime
inner join employee ON WorkingTime.employee = employee.id
inner join appointment ON WorkingTime.appointment = appointment.id
INNER JOIN event ON appointment.event = event.id
inner join customer on event.customer = customer.id
WHERE WorkingTime.end >= '2019-10-27 02:00:00' AND WorkingTime.end <= '2019-10-27 03:00:00';

/* Mitarbeiter eines Standorts, die ihren letzten Job in einem bestimmten Zeitraum hatten inklusive der Arbeitstage in diesem Zeitraum */
SELECT first_name AS Vorname, last_name AS Nachname, MAX(begin) AS LastJob, active AS Aktiv, employment_date AS Ersteintrittsdatum, anz AS Arbeitstage_2019
FROM employee
INNER JOIN appointment ON employee.id = appointment.employee AND appointment.status = "Assigned"
INNER JOIN event ON appointment.event = event.id
LEFT JOIN (
    SELECT employee, COUNT(*) AS anz FROM (
        SELECT employee
        FROM WorkingTime
        INNER JOIN employee ON WorkingTime.employee = employee.id
        WHERE `begin` >= '2019-01-01 00:00:00' AND `begin` < '2020-01-01 00:00:00' AND (employee.location = 2)
        GROUP BY employee.id, YEAR(`begin`), MONTH(`begin`), DAY(`begin`)
    ) s1
    GROUP BY employee
) s1 ON employee.id = s1.employee 
WHERE employee.location = 2
GROUP BY employee.id
HAVING LastJob >= '2019-01-01 00:00:00' AND LastJob < '2020-01-01 00:00:00'
LIMIT 0, 2000;

/* Aktive Mitarbeiter eines Standorts, inkl. PGS und Vertragsstunden p.M. zum jetzigen Zeitpunkt */
SELECT first_name AS Vorname, last_name AS Nachname, e1.socialSecurityGroup AS PGS, IF(e1.contractHoursBase = "Monthly", e1.contractHours, e1.contractHours * 4.3334285714) AS "Vertragsstunden (p.M.)"
FROM employee
LEFT JOIN (
    SELECT id, begin, end, employee, socialSecurityGroup, contractHours, contractHoursBase, MAX(`begin`) OVER (PARTITION BY employee) AS maxBegin
    FROM Employment
    WHERE `begin` < NOW()
) e1 ON employee.id = e1.employee AND e1.`begin` = e1.maxBegin
WHERE active = 1 AND location = 2
ORDER BY last_name, first_name;

/* Monatliche abgerufene Stunden aller Kunden in einem Jahr*/
SELECT c.name AS Kunde, l.name AS Standort,
REPLACE(Stunden1, '.', ',') AS Jan18,
REPLACE(Stunden2, '.', ',') AS Feb18,
REPLACE(Stunden3, '.', ',') AS Mar18,
REPLACE(Stunden4, '.', ',') AS Apr18,
REPLACE(Stunden5, '.', ',') AS Mai18,
REPLACE(Stunden6, '.', ',') AS Jun18,
REPLACE(Stunden7, '.', ',') AS Jul18,
REPLACE(Stunden8, '.', ',') AS Aug18,
REPLACE(Stunden9, '.', ',') AS Sep18,
REPLACE(Stunden10, '.', ',') AS Okt18,
REPLACE(Stunden11, '.', ',') AS Nov18,
REPLACE(Stunden12, '.', ',') AS Dez18
FROM customer c
LEFT JOIN UMDLocation l ON c.location = l.id
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden1
    FROM `event`
    WHERE `event`.`begin` >= '2018-01-01 00:00:00' AND `event`.`begin` < '2018-02-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t1 ON c.id = t1.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden2
    FROM `event`
    WHERE `event`.`begin` >= '2018-02-01 00:00:00' AND `event`.`begin` < '2018-03-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t2 ON c.id = t2.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden3
    FROM `event`
    WHERE `event`.`begin` >= '2018-03-01 00:00:00' AND `event`.`begin` < '2018-04-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t3 ON c.id = t3.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden4
    FROM `event`
    WHERE `event`.`begin` >= '2018-04-01 00:00:00' AND `event`.`begin` < '2018-05-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t4 ON c.id = t4.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden5
    FROM `event`
    WHERE `event`.`begin` >= '2018-05-01 00:00:00' AND `event`.`begin` < '2018-06-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t5 ON c.id = t5.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden6
    FROM `event`
    WHERE `event`.`begin` >= '2018-06-01 00:00:00' AND `event`.`begin` < '2018-07-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t6 ON c.id = t6.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden7
    FROM `event`
    WHERE `event`.`begin` >= '2018-07-01 00:00:00' AND `event`.`begin` < '2018-08-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t7 ON c.id = t7.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden8
    FROM `event`
    WHERE `event`.`begin` >= '2018-08-01 00:00:00' AND `event`.`begin` < '2018-09-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t8 ON c.id = t8.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden9
    FROM `event`
    WHERE `event`.`begin` >= '2018-09-01 00:00:00' AND `event`.`begin` < '2018-10-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t9 ON c.id = t9.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden10
    FROM `event`
    WHERE `event`.`begin` >= '2018-10-01 00:00:00' AND `event`.`begin` < '2018-11-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t10 ON c.id = t10.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden11
    FROM `event`
    WHERE `event`.`begin` >= '2018-11-01 00:00:00' AND `event`.`begin` < '2018-12-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t11 ON c.id = t11.customer
LEFT JOIN (
    SELECT customer, SUM(ABS(UNIX_TIMESTAMP(`event`.`end`) - UNIX_TIMESTAMP(`event`.`begin`)) / 3600 * quantity) AS Stunden12
    FROM `event`
    WHERE `event`.`begin` >= '2018-12-01 00:00:00' AND `event`.`begin` < '2019-01-01 00:00:00' AND `event`.`cancelled` = 0
    GROUP BY customer
) t12 ON c.id = t12.customer
WHERE (Stunden1 IS NOT NULL OR Stunden2 IS NOT NULL OR Stunden3 IS NOT NULL OR Stunden4 IS NOT NULL OR Stunden5 IS NOT NULL OR Stunden6 IS NOT NULL OR Stunden7 IS NOT NULL OR Stunden8 IS NOT NULL OR Stunden9 IS NOT NULL OR Stunden10 IS NOT NULL OR Stunden11 IS NOT NULL OR Stunden12 IS NOT NULL)
ORDER BY c.name ASC;

/* Erster Job neuer Mitarbeiter eines Standorts ab einem bestimmten Datum */
SELECT first_name AS Vorname, last_name AS Nachname, MIN(begin) AS "Erster Job", active AS Aktiv FROM employee
INNER JOIN appointment ON employee.id = appointment.employee AND appointment.status = "Assigned"
INNER JOIN event ON appointment.event = event.id
WHERE employee.location = 2
GROUP BY employee.id
HAVING MIN(begin) >= '2019-01-01 00:00:00'
ORDER BY MIN(begin)

/* Aktive Mitarbeiter nach Monat und Standort innerhalb eines Zeitraums */
SELECT MONTH(`begin`) AS Monat, employee.location, COUNT(DISTINCT employee) AS Anzahl
FROM appointment
INNER JOIN `event` ON appointment.`event` = `event`.id
INNER JOIN employee ON appointment.employee = employee.id
WHERE `status` = "Assigned" AND `begin` >= '2019-01-01 00:00:00' AND `begin` < '2020-01-01 00:00:00'
GROUP BY MONTH(`begin`), employee.location

/* Anzahl der Nettostunden und der zeiterfassten Einsätze für Kunden in zwei Jahren und nach Standorten gefiltert */
SELECT `name`, t2.Nettostunden AS Nettostunden_2019, t4.Nettostunden AS Nettostunden_2020, anz1.anz AS Anzahl_2019, anz2.anz AS Anzahl_2020, tblCustomer.location AS Standort
FROM customer tblCustomer
LEFT JOIN (
	SELECT id, `name` AS Kunde, SUM(Stunden) AS Nettostunden FROM (
		SELECT customer.id, customer.`name`, (TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden FROM customer
		INNER JOIN `event` ON customer.id = `event`.customer
		INNER JOIN appointment ON `event`.id = appointment.`event` AND `status` = "Assigned"
		INNER JOIN employee ON appointment.employee = employee.id
		INNER JOIN WorkingTime ON appointment.id = WorkingTime.appointment
		WHERE WorkingTime.`begin` >= '2019-01-01 00:00:00' AND WorkingTime.`begin` < '2020-01-01 00:00:00'
	) t1
	GROUP BY id
) t2 ON tblCustomer.id = t2.id
LEFT JOIN (
    SELECT subCustomerCount.id, COUNT(subCustomerCount.id) AS anz
    FROM (
        SELECT customer.id
        FROM WorkingTime
        INNER JOIN appointment ON WorkingTime.appointment = appointment.id
        INNER JOIN event ON appointment.event = event.id
        INNER JOIN customer ON event.customer = customer.id
        WHERE customer.location IN (1,3,4) AND event.begin >= '2019-01-01 00:00:00' AND event.begin < '2020-01-01 00:00:00'
        GROUP BY customer.id, event.id
        ORDER BY customer.id
        
    ) subCustomerCount
    GROUP BY subCustomerCount.id
) anz1 ON tblCustomer.id = anz1.id
LEFT JOIN (
	SELECT id, `name` AS Kunde, SUM(Stunden) AS Nettostunden FROM (
		SELECT customer.id, customer.`name`, (TIME_TO_SEC(TIMEDIFF(`WorkingTime`.`end`, `WorkingTime`.`begin`)) / 3600 - (breakMins / 60)) AS Stunden FROM customer
		INNER JOIN `event` ON customer.id = `event`.customer
		INNER JOIN appointment ON `event`.id = appointment.`event` AND `status` = "Assigned"
		INNER JOIN employee ON appointment.employee = employee.id
		INNER JOIN WorkingTime ON appointment.id = WorkingTime.appointment
		WHERE WorkingTime.`begin` >= '2020-01-01 00:00:00' AND WorkingTime.`begin` < '2021-01-01 00:00:00'
	) t3
	GROUP BY id
) t4 ON tblCustomer.id = t4.id
LEFT JOIN (
    SELECT subCustomerCount.id, COUNT(subCustomerCount.id) AS anz
    FROM (
        SELECT customer.id
        FROM WorkingTime
        INNER JOIN appointment ON WorkingTime.appointment = appointment.id
        INNER JOIN event ON appointment.event = event.id
        INNER JOIN customer ON event.customer = customer.id
        WHERE customer.location IN (1,3,4) AND event.begin >= '2020-01-01 00:00:00' AND event.begin < '2021-01-01 00:00:00'
        GROUP BY customer.id, event.id
        ORDER BY customer.id
        
    ) subCustomerCount
    GROUP BY subCustomerCount.id
) anz2 ON tblCustomer.id = anz2.id
WHERE tblCustomer.location IN (1,3,4)
ORDER BY `name`
LIMIT 0, 1000

/* Urlaubstage und Beschäftigungszeiträume für ein bestimmtes Datum */
SELECT first_name AS Vorname, last_name AS Nachname, e1.socialSecurityGroup AS PGS, e1.isIGZ AS IGZ, e1.vacationDays AS Urlaubstage, e1.begin AS "BZ-Beginn", e1.end AS "BZ-Ende", employee.location AS Standort
FROM employee
LEFT JOIN (
    SELECT id, begin, end, employee, socialSecurityGroup, isIGZ, vacationDays, MAX(`begin`) OVER (PARTITION BY employee) AS maxBegin
    FROM Employment
    WHERE `begin` <= '2021-01-01 00:00:00'
) e1 ON employee.id = e1.employee AND e1.`begin` = e1.maxBegin
WHERE active = 1
ORDER BY last_name, first_name;

-- Abfrage zur ANÜ Statistik (pg-ready)
-- Gib alle angemeldeten oder in einem Zeitraum tätigen Mitarbeiter zurück
SELECT
    last_name AS "Nachname",
    first_name AS "Vorname",
    loc.name AS "Standort",
    CASE WHEN registered = TRUE THEN 'Ja' ELSE 'Nein' END AS "Angemeldet",
    CASE WHEN working.id IS NOT NULL THEN 'Ja' ELSE 'Nein' END AS "Einsatz",
    last_employment.end AS "Beendet"
FROM employee
LEFT JOIN (
    SELECT DISTINCT employee AS id
    FROM "WorkingTime"
    WHERE begin >= '2020-07-22 00:00:00' AND begin < NOW() AND tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e'
) AS working ON employee.id = working.id -- get employees who were working in timespan
LEFT JOIN (
    SELECT e1.employee, begin, "end"
    FROM "Employment" e1
    INNER JOIN (
        SELECT employee, MAX(begin) AS max_begin
        FROM "Employment"
        WHERE "begin" <= NOW() AND tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e'
        GROUP BY employee
    ) AS e2 ON e1.employee = e2.employee AND e1."begin" = e2.max_begin
) AS last_employment ON employee.id = last_employment.employee -- get last employment before now
LEFT JOIN "UMDLocation" loc ON employee.location = loc.id AND employee.tenant = loc.tenant
WHERE (registered = TRUE OR working.id IS NOT NULL) AND employee.tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e' -- get only registered employees or employees who worked in timespan
ORDER BY "location", last_name, first_name


/* Lohnerhöhung / Lohnstufenänderung*/
/* Neues Verfahren (postgres-geeignet) */
/* Step 1: Alle alten und neuen Entgeltgruppen geordnet auslesen (group ändern, um die Gruppe zu ändern) */
SELECT "level" AS "Stufe", replace(amount::text, '.', ',') AS "Betrag", replace(bonus::text, '.', ',') AS "ÜTZ", replace((amount+bonus)::text, '.', ',') AS "Gesamt", id AS "ID" FROM corteam."UMDWageLevel"
WHERE "group" = 54 AND tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e'
ORDER BY "level";
/* Step 2: Gegenüberstellen der Gruppen in Excel - alte Stufen versuchen auf neue Stufen zu mappen mittels XVERWEIS, wenn die Beträge sich nicht ändern sollen von alt auf neu */
/* Sicherstellen, dass alle alten Stufen neue IDs zugewiesen haben - die ersten 2-3 Stufen müssen meistens händisch gesetzt werden */
/* Beispielformel: =XVERWEIS(D5;$L$2:$L$21;$M$2:$M$21;"") */
/* Step 3: Alle abändern, bei denen eine alte Lohnstufe zum Stichtag oder danach beginnt (manuelles Abändern, wenn wenige Einträge (wahrscheinlich)) */
/* Ermitteln der Fälle (group bezieht sich in der Abfrage auf die alten Lohnstufen, die nach dem validFrom-Datum angelegt wurden):  */
SELECT *
FROM "UMDEmployeeWageLevel" ewl
INNER JOIN "UMDWageLevel" wl ON ewl."wageLevel" = wl.id AND ewl.tenant = wl.tenant
WHERE cancellation = FALSE AND "validFrom" >= '2022-04-01' AND "group" IN (45,46,47,48) AND ewl.tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e';
/* Step 4: Alle abändern, bei denen eine alte Lohnstufe über den Stichtag läuft */
/* generiert durch Excel-Formel (tenant anpassen!):
=VERKETTEN("INSERT INTO ""UMDEmployeeWageLevel"" (employee, ""wageLevel"", ""validFrom"", ""user"", updated, tenant) ";
"SELECT employee, "&F2&" AS ""wageLevel"", '2022-04-01 00:00:00' AS ""validFrom"", ""user"", NOW() AS updated, tenant ";
"FROM ""UMDEmployeeWageLevel"" ";
"WHERE cancellation = FALSE AND ""validFrom"" < '2022-04-01 00:00:00' AND (""validUntil"" > '2022-04-01 00:00:00' OR ""validUntil"" IS NULL) AND ""wageLevel"" = "&E92&" AND tenant = '01158e7c-8985-44ab-8527-155681a19c7a';")
*/
/* Beispiel:
INSERT INTO "UMDEmployeeWageLevel" (employee, "wageLevel", "validFrom", "user", updated, tenant) SELECT employee, 998 AS "wageLevel", '2022-04-01 00:00:00' AS "validFrom", "user", NOW() AS updated, tenant FROM "UMDEmployeeWageLevel" WHERE cancellation = FALSE AND "validFrom" < '2022-04-01 00:00:00' AND ("validUntil" > '2022-04-01 00:00:00' OR "validUntil" IS NULL) AND "wageLevel" = 871 AND tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e';
*/
/* Step 4: Aufruf von https://allstars.corteam.net/site/rebuildEmployeeWageLevels um validUntil zu rebuilden -> für andere Tenants andere Subdomains */
/* Alle Datensätze, deren Lohnstufe vor dem Stichtag ausläuft brauchen nicht berücksichtigt werden - ebenso wie cancellation = 1 */
/* Step 5: Für Adi alle abrufen, bei denen die Lohnstufe über den Stichtag läuft oder die eine Lohnstufe haben, die am Stichtag oder danach beginnt und nicht in die Lohngruppen fällt, die geändert wurden (Vorjahresgruppe + aktuelle Gruppe) */
SELECT first_name AS "Vorname", last_name AS "Nachname", "validFrom" AS "Gültig ab", "validUntil" AS "Gültig bis", amount AS "Basislohn", bonus AS "Zulage", loc.name AS "Standort", employee.active AS "Aktiv", employee.registered AS "Angemeldet"
FROM "UMDEmployeeWageLevel" ewl
INNER JOIN "UMDWageLevel" wl ON ewl."wageLevel" = wl.id AND ewl.tenant = wl.tenant
INNER JOIN employee ON ewl.employee = employee.id AND ewl.tenant = employee.tenant
LEFT JOIN "UMDLocation" loc ON employee.location = loc.id AND employee.tenant = loc.tenant
WHERE cancellation = FALSE AND "group" NOT IN (45,46,47,48,51,52,53,54) AND ("validUntil" > '2022-04-01 00:00:00' OR "validUntil" IS NULL) AND ewl.tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e'
ORDER BY employee.location, last_name, first_name


/* Gearbeitete und vertragliche Stunden von Mitarbeitern nach Monaten in einem Zeitraum */
SELECT tblWorkingTimes.*, Employment.contractHours, Employment.contractHoursBase, Employment.begin, Employment.end
FROM (
    SELECT
    WorkingTime.employee,
    employee.first_name,
    employee.last_name,
    YEAR(WorkingTime.begin) AS 'year',
    MONTH(WorkingTime.begin) AS 'month',
    SUM(ABS(UNIX_TIMESTAMP(WorkingTime.end) - UNIX_TIMESTAMP(WorkingTime.begin)) / 60.0 - (WorkingTime.breakMins)) / 60.0 AS netHours
    FROM WorkingTime
    INNER JOIN employee ON WorkingTime.employee = employee.id
    WHERE WorkingTime.begin >= '2020-05-01 00:00:00' AND WorkingTime.begin < '2021-06-01 00:00:00' AND employee.location = 2
    GROUP BY WorkingTime.employee, YEAR(WorkingTime.begin), MONTH(WorkingTime.begin)
    ORDER BY employee.last_name, employee.first_name, WorkingTime.employee, WorkingTime.begin ASC
) tblWorkingTimes
LEFT JOIN Employment ON tblWorkingTimes.employee = Employment.employee AND Employment.begin < DATE_ADD(
    STR_TO_DATE(CONCAT(tblWorkingTimes.year, '-', tblWorkingTimes.month, '-', '1 00:00:00'), '%Y-%c-%e %H:%i:%s'),
    INTERVAL 1 MONTH
)
LEFT JOIN Employment EmploymentMax ON tblWorkingTimes.employee = EmploymentMax.employee AND Employment.begin < EmploymentMax.begin AND EmploymentMax.begin < DATE_ADD(
    STR_TO_DATE(CONCAT(tblWorkingTimes.year, '-', tblWorkingTimes.month, '-', '1 00:00:00'), '%Y-%c-%e %H:%i:%s'),
    INTERVAL 1 MONTH
) /* Tabelle, um den neuesten, aktuellen BZ zu bestimmen */
WHERE EmploymentMax.id IS NULL

/* Aufträge und Mitarbeiter aus der Zeiterfassung für einen Standort in einem Zeitraum (28.06.2021 für Jan) */
SELECT customer.name, event.name, event.workplaceName, event.street, event.zip_code, event.city, event.invoice_no, first_name, last_name, WorkingTime.begin, WorkingTime.end, breakMins, travelMins, moneyAdd, moneyAddHourly
FROM WorkingTime
INNER JOIN employee ON WorkingTime.employee = employee.id
LEFT JOIN appointment ON WorkingTime.appointment = appointment.id
LEFT JOIN event ON appointment.event = event.id
LEFT JOIN customer ON event.customer = customer.id
WHERE employee.location = 2 AND WorkingTime.begin >= '2021-05-01 00:00:00' AND WorkingTime.end < '2021-06-01 00:00:00'
ORDER BY event.begin, event.end

/* Generieren von EÜV-PDF-Links für einen Mitarbeiter für einen Zeitraum */
SELECT
customer.name AS Kunde,
event.name AS Einsatz,
event.workplaceName AS Einsatzort,
event.street AS 'Straße',
event.zip_code AS PLZ,
event.city AS Ort,
first_name AS Vorname,
last_name AS Nachname,
CONCAT('https://allstars.corteam.net/event/showDocs?eventId=', event.id, '&docType=contract&customerLocation=', customer_location.id,'&includeName=1&includeCitizenship=0&includeBirthDate=0&includeBirthPlace=0&includeSocialSecurityNumber=0&includeIdentificationCardNumber=0') AS Link
FROM appointment
INNER JOIN event ON appointment.event = event.id
INNER JOIN employee ON appointment.employee = employee.id
LEFT JOIN customer ON event.customer = customer.id
LEFT JOIN customer_location ON customer_location.id = 
(
    SELECT id
    FROM customer_location
    WHERE isDocAddress = 1 AND customer = customer.id
    LIMIT 1
)
WHERE employee = 3778 AND appointment.status = 'Assigned' AND begin >= '2020-05-01 00:00:00' AND begin < '2020-06-01 00:00:00'

-- Vorname | Nachname | Bisher geleistete Stunden | Eingeplante Stunde für den aktuellen Monat (ohne Schulungen) | Vertragsstunden | Datev Nr.
SELECT first_name AS Vorname, last_name AS Nachname, UMDLocation.name AS Standort,
REPLACE(hours_assigned, '.', ',') AS Eingeplant,
REPLACE(net_hours, '.', ',') AS Erfasst,
REPLACE(CASE WHEN s1.contractHoursBase = "Weekly" THEN s1.contractHours * 4.3334285714 ELSE s1.contractHours END, '.', ',') AS "Vertrag",
s1.social_security_group AS "PGS",
s1.datevEmployeeNumber AS "Datev-Nr."
FROM employee e1
LEFT JOIN UMDLocation ON e1.location = UMDLocation.id
LEFT JOIN (
    SELECT employee AS id, SUM(ABS(UNIX_TIMESTAMP(event.end) - UNIX_TIMESTAMP(event.begin))) / 3600.0 AS hours_assigned
    FROM appointment
    INNER JOIN event ON appointment.event = event.id
    WHERE event.cancelled = 0 AND event.status_type NOT IN ('Training') AND appointment.status = 'Assigned' AND event.`begin` >= '2021-07-01 00:00:00' AND event.`begin` < '2021-08-01 00:00:00'
    GROUP BY employee
) t1 ON e1.id = t1.id
LEFT JOIN (
    SELECT employee AS id, SUM(ABS(UNIX_TIMESTAMP(WorkingTime.end) - UNIX_TIMESTAMP(WorkingTime.begin)) / 60.0 - (WorkingTime.breakMins)) / 60.0 AS net_hours
    FROM WorkingTime
    WHERE `begin` >= '2021-07-01 00:00:00' AND `begin` < '2021-08-01 00:00:00'
    GROUP BY employee
) t2 ON e1.id = t2.id
LEFT JOIN (
    SELECT emp1.employee AS id, contractHours, contractHoursBase, social_security_group, datevEmployeeNumber
    FROM Employment emp1
    INNER JOIN (
        SELECT employee, MAX(`begin`) AS maxBegin
        FROM Employment
        WHERE `begin` <= '2021-07-31 00:00:00'
        GROUP BY employee
    ) AS emp2 ON emp1.employee = emp2.employee AND emp1.`begin` = emp2.maxBegin
    LEFT JOIN position ON emp1.position = position.id
) s1 ON e1.id = s1.id
WHERE (net_hours IS NOT NULL OR hours_assigned IS NOT NULL)
ORDER BY e1.last_name, e1.first_name
LIMIT 0, 1000

/* PG: Arbeitstage und PGS von Mitarbeitern in einem bestimmten Zeitraum und für einen bestimmten Standort (beachten: alle WHERE-Conditions anpassen!) */
SELECT first_name AS "Vorname", last_name AS "Nachname", emp.social_security_group AS "PGS", wtdays.count_days AS "Arbeitstage", loc.name AS "Standort"
FROM employee e
LEFT JOIN (
    SELECT employee, begin, social_security_group, MAX(begin) OVER (PARTITION BY employee) AS max_begin, "Employment".tenant
    FROM "Employment"
    INNER JOIN position ON "Employment".position = position.id AND "Employment".tenant = position.tenant
    WHERE "Employment".tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e' AND begin < NOW()
) emp ON e.id = emp.employee AND e.tenant = emp.tenant AND emp.begin = emp.max_begin
LEFT JOIN (
    SELECT employee, COUNT(DISTINCT begin::date) AS count_days -- count only one row per day
    FROM "WorkingTime" wt
    INNER JOIN employee e ON wt.employee = e.id AND wt.tenant = e.tenant
    WHERE begin >= '2021-01-01 00:00:00' AND begin < '2022-01-01 00:00:00' AND e.active AND e.location IN(1,3,4,5,6,7,9) AND wt.tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e'
    GROUP BY wt.employee
) wtdays ON e.id = wtdays.employee
LEFT JOIN "UMDLocation" loc ON e.location = loc.id AND e.tenant = loc.tenant
WHERE e.active AND e.location IN(1,3,4,5,6,7,9) AND e.tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e'
ORDER BY last_name, first_name;

/* PG: KUG-Abfrage für Steffi - Anzahl der Mitarbeiter nach Monaten */
SELECT
	last_name AS "Nachname",
	first_name AS "Vorname",
	cc.name AS "Kostenstelle",
	loc.name AS "Standort",
	e.active AS "Aktuell aktiv",
	emp.begin AS "Beginn",
	emp.end AS "Ende",
	emp.joining AS "Eintritt",
	emp.leaving AS "Austritt"
FROM employee e
INNER JOIN "Employment" emp ON e.id = emp.employee AND '2022-03-01 00:00:00' >= emp.begin AND (emp.end IS NULL OR '2022-04-01 00:00:00' <= emp.end) AND e.tenant = emp.tenant
LEFT JOIN "UMDLocation" loc ON e.location = loc.id AND e.tenant = loc.tenant
LEFT JOIN "UMDCostCenter" cc ON e."costCenter" = cc.id AND e.tenant = cc.tenant
WHERE e.tenant = 'fe504f01-1045-4605-a03e-96a2f932da6e'
ORDER BY e.location, e.last_name, e.first_name;