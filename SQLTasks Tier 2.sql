/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

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

SELECT name
FROM Facilities
WHERE membercost > 0;


/* Q2: How many facilities do not charge a fee to members? */

/* A2: 4 */
SELECT COUNT(*) AS count_facilities
FROM Facilities
WHERE membercost = 0;


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost = 0
	AND membercost < .2 * monthlymaintenance;


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
	IF(maintenance > 100, 'expensive', 'cheap') AS label
FROM Facilities;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate = (SELECT MAX(joindate) FROM Members);


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

/* Springboard doesn't seem to like this query because of CONCAT(). 
   You can run the same thing without the CONCAT call and get everything in separate columns. */
SELECT tennis_courts.name, CONCAT(Members.firstname, ' ', Members.surname) AS member_name
FROM (SELECT name, facid FROM Facilities WHERE name LIKE 'Tennis Court _') AS tennis_courts
INNER JOIN Bookings USING(facid)
INNER JOIN Members USING(memid);


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT Facilities.name AS facility, CONCAT(Members.firstname, ' ', Members.surname) AS name
	IF(Bookings.memid = 0, (Facilities.guestcost * Bookings.slots),
      (Facilities.membercost * Bookings.slots)) AS cost
FROM Bookings
INNER JOIN Facilities USING(facid)
INNER JOIN Members USING(memid)
WHERE DATE(Bookings.starttime) = '2012-09-14'
	AND IF(Bookings.memid = 0, Facilities.guestcost, Facilities.membercost) * Bookings.slots > 30
ORDER BY cost DESC;


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

/* Refactoring the previous query to use a subquery causes the website to block my request,
   but I believe this is the correct query to answer the question. */
SELECT b.facility, CONCAT(Members.firstname, ' ', Members.surname), b.cost 
FROM (SELECT Facilities.name AS facility, Bookings.memid,
     IF(Bookings.memid = 0, Facilities.guestcost, Facilities.membercost) * Bookings.slots AS cost
     FROM Bookings
     INNER JOIN Facilities USING(facid)
     WHERE DATE(Bookings.starttime) = '2012-09-14'
         AND IF (Bookings.memid = 0, Facilities.guestcost, Facilities.membercost) * Bookings.slots > 30) AS b
INNER JOIN Members USING(memid)
ORDER BY cost DESC;


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT booking_costs.name, SUM(booking_costs.cost) AS revenue
FROM (
	SELECT Facilities.name, 
		CASE
			WHEN Bookings.memid = 0 THEN Facilities.guestcost * Bookings.slots
			ELSE Facilities.membercost * Bookings.slots
		END AS cost
	FROM Bookings
	INNER JOIN Facilities USING(facid)
	) AS booking_costs
GROUP BY booking_costs.name
HAVING revenue < 1000
ORDER BY revenue DESC;


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT Members.surname || ', ' || Members.firstname) AS member,
	Recommender.surname || ', ' || Recommender.firstname) AS recommender
FROM Members
INNER JOIN Members AS Recommender
ON Members.recommendedby = Recommender.memid
ORDER BY member;


/* Q12: Find the facilities with their usage by member, but not guests */

SELECT Facilities.name, COUNT(Bookings.memid) AS usages_count,
	COUNT(DISTINCT Bookings.memid) AS unique_member_usage,
	SUM(Bookings.slots) AS total_slots_booked
FROM Facilities
INNER JOIN Bookings USING(facid)
WHERE Bookings.memid <> 0
GROUP BY name;


/* Q13: Find the facilities usage by month, but not guests */

SELECT strftime('%m', Bookings.starttime) AS month, Facilities.name,
	COUNT(Bookings.bookid) AS num_bookings
FROM Bookings
INNER JOIN Facilities USING(facid)
WHERE Bookings.memid <> 0
GROUP BY month, name
ORDER BY month, name;