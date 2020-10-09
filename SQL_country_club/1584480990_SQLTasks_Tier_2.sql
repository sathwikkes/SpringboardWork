/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.


PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name from Facilities WHERE membercost <> 0;

/* Q2: How many facilities do not charge a fee to members? */

SELECT name from Facilities WHERE membercost > 0; 

--5 facilities 

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance 
FROM Facilities 
WHERE membercost <> 0 AND membercost < 0.20*monthlymaintenance;


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities 
WHERE name LIKE '%2';

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
CASE WHEN monthlymaintenance > 100 THEN 'expensive'
     ELSE 'cheap' END AS CheaporExpensive
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

--gets the last one joined
SELECT firstname, surname, joindate
FROM Members
WHERE joindate = (
    SELECT MAX(joindate)
    FROM Members);

--orders by last to first joined 
SELECT firstname, surname, MAX(joindate) AS 'MostRecent'
FROM Members
GROUP BY firstname,surname
ORDER BY MostRecent DESC;

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

--version 1 more efficient 
SELECT DISTINCT CONCAT(m.firstname, ' ',m.surname) as member,f.name 
FROM Members as m
    INNER JOIN Bookings as b
    ON m.memid = b.memid 

    INNER JOIN Facilities as f 
    ON b.facid= f.facid 
 WHERE b.facid = 0 or b.facid = 1
ORDER BY member, f.name

--version 2
SELECT DISTINCT CONCAT(m.firstname,' ',m.surname) as member, f.name
FROM Bookings as b
INNER JOIN Facilities as f
ON b.facid = f.facid 
INNER JOIN Members as m 
ON b.memid = m.memid
WHERE b.facid = 0 OR b.facid = 1
ORDER BY member, f.name;


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT name, CONCAT(m.firstname,' ',m.surname) AS member,
        CASE WHEN b.memid = 0 THEN guestcost*slots
             ELSE membercost*slots 
        END AS cost
     FROM Members AS m
      INNER JOIN Bookings AS b
      ON m.memid = b.memid

      INNER JOIN Facilities AS f
      ON b.facid = f.facid 
    WHERE starttime BETWEEN '2012-09-14 00:00:00' AND '2012-09-14 23:59:59'
     AND CASE WHEN b.memid = 0 THEN guestcost*slots
     ELSE membercost*slots END > 30 
ORDER BY cost DESC


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT d.name, 
       CONCAT(m.firstname,' ',m.surname) AS member,
       d.cost
      FROM Members AS m
         INNER JOIN (SELECT name, 
                     memid, 
                     CASE WHEN memid = 0 THEN guestcost*slots
                     ELSE membercost*slots
                    END AS cost
                  FROM Bookings AS b
                   INNER JOIN Facilities AS f
                   on b.facid = f.facid 
                  WHERE starttime BETEEN '2012-09-14 00:00:00' AND '2012-09-14 23:59:59') AS d
                   ON m.memid = d.memid 
WHERE d.cost >30 
ORDER BY d.cost DESC;


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT name, 
      (SUM(d.cost) - initialoutlay - (3*monthlymaintenance)) AS revenue
  FROM Facilities as f
       INNER JOIN (SELECT f.facid, bookid, 
                          CASE WHEN memid = 0 THEN guestcost*slots
                          ELSE membercost*slots
                     END AS cost
                   FROM Bookings as b
                        INNER JOIN Facilities as f
                        on b.facid = f.acid) AS d
       ON d.facid = f.facid
GROUP BY f.facid
  HAVING revenue < 1000
ORDER BY revenue;
                        

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT CONCAT( m.firstname, ' ', m.surname ) AS member, m.recommendedby, CONCAT(r.firstname, ' ', r.surname) as recommendedbyname
FROM Members AS m
LEFT JOIN Members AS r ON m.recommendedby = r.memid
WHERE m.recommendedby <> ' '
ORDER BY  r.surname;


/* Q12: Find the facilities with their usage by member, but not guests */
SELECT DISTINCT CONCAT(m.firstname, ' ',m.surname) AS member, f.name
FROM Members as m 
    INNER JOIN Bookings as b
    ON m.memid = b.memid

    INNER JOIN Facilities as f
    on b.facid = f.facid
WHERE m.memid <> 0
ORDER BY f.name;


/* Q13: Find the facilities usage by month, but not guests */

SELECT f.name, EXTRACT(MONTH from b.starttime) AS month
FROM Members as m 
    INNER JOIN Bookings as b
    ON m.memid = b.memid

    INNER JOIN Facilities as f
    on b.facid = f.facid
WHERE m.memid <> 0
GROUP BY month;

