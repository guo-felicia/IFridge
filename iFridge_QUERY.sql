SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE assigning;
TRUNCATE reminder;
SET FOREIGN_KEY_CHECKS = 1;

USE ifridge; 


-- all in one!
-- let your whole family connect to the fridge
-- easy to track, easy to communicate!

-- 1
-- number of users per fridge

SELECT
    fridge_id,
    COUNT(user_id) num_users
FROM 
    fridge 
    JOIN belongings USING (fridge_id)
GROUP BY fridge_id;

-- 2
-- maximum fridge capacity for each family 
-- distinct records for users with same fridge but different last names

SELECT 
    fridge_id, 
    max_capacity_litter, 
    last_name
FROM 
    fridge f 
    JOIN belongings USING (fridge_id) 
    JOIN fridge_size fs ON (f.size_id = fs.fridge_size_id)
    JOIN user USING (user_id)
GROUP BY
    fridge_id,
    last_name
ORDER BY fridge_id;



-- Let's try scanning and adding an inventory into your fridge!
-- the fridge will have all the information needed by scanning the barcodes on inventories.

-- 3
-- Tina(user_id=12, fridge_id=8) bought and scanned a box of Prime Rib Steak this afternoon.
-- Now the fridge should update its inventory table to reflect on this change.
-- Given that the steak (nutrient_id=2000, 1kg, expired in 14 days) is not a necessity for her and it should be freezed.

SELECT * FROM inventory;
CALL store('Prime Rib Steak','FREEZE', 1, 1000, 14, 0, 8, 2000);
SELECT * FROM inventory;

-- during the global pandemic, it is hard for 
-- certain groups of people to go outside and bring groceries home.
-- let's see what we can do!

-- 4
-- see the percentage of food types in the elder's fridges

SELECT
	classification,
	ROUND(COUNT(*)/(
		SELECT COUNT(*) 
		FROM 
			inventory 
			JOIN nutrient USING (nutrient_id) 
			JOIN belongings USING (fridge_id)
			JOIN user USING (user_id)
		WHERE age >= 65),2) percentage
FROM
	inventory 
	JOIN nutrient USING (nutrient_id) 
	JOIN belongings USING (fridge_id)
	JOIN user USING (user_id)
WHERE age >= 65
GROUP BY classification
ORDER BY COUNT(*) DESC;

-- 5
-- the community decides to have volunteers deliver fresh vegetable and fruits
-- to the families with elder people.
-- this is a list of elder people ordering by the number of fresh food types in their fridges.

CALL coronaCare();



-- nutrient supplements
-- iFridge supports the connection with your EMR!
-- with the your authorization, we will recommend a various range of food according to your EMR.
-- for the elder, however, we suggest them to follow the specific guidance of their PCP.

-- 6
-- People value their privacy, and they are cautious about sharing personal health status.
-- What is the percentage of users connecting their iFridge accounts to their EMR?

SELECT
    ROUND((
        SELECT COUNT(*) 
        FROM
            user 
            JOIN belongings USING (user_id) 
        WHERE connected_to_emr = 1)/
        COUNT(*),2) percentage_connected
FROM
    user 
    JOIN belongings USING (user_id);

-- 7
-- Renaud(id:4), Tina(id:12) and Anya(id:19) all participated in the annual medical examination of their company.
-- Back home, they all want to eat heathier according to their results in EMR,
-- and each of them has different ideas to acquire those nutrients from.

CALL nutrientSupplements(4,'vitamin_c_mg','Fruits');
CALL nutrientSupplements(12,'protein_g','Fish');
CALL nutrientSupplements(19,'iron_mg','Vegetables');
-- These should fail
-- Age restriction
CALL nutrientSupplements(3,'calcium_mg','Meats');
-- Not connected to EMR
CALL nutrientSupplements(20,'zinc_mg','Vegetables');


-- Fridge Care
-- Give reminders to users whose fridges need to be maintained
-- If the date is passed, send an alert to the user

-- 8

-- need maintenance, alert
CALL fridgeCare(2,1);
-- done maintenance, remind the next maintenance date
CALL fridgeCare(18,6);

SELECT * FROM reminder;
SELECT * FROM assigning;


-- Necessity Supply
-- a reminder to the user about their necessity shortage
-- no more signs when you open the fridge and find no egg for breakfast...

-- 9
-- In general, a user wants to know if there is a necessity shortage
-- the user wants to be notified about a necessity shortage if shortage>=50%
-- Given the number of necessities needed

-- > 0%, < 50%
CALL necessityPercentage(8,4,4);
-- = 50%
CALL necessityPercentage(12,8,5);
-- > 50%, < 100%
CALL necessityPercentage(5,2,8);
-- = 100%
CALL necessityPercentage(20,7,11);

SELECT * FROM reminder;
SELECT * FROM assigning;

-- 10
-- the fridge should display if any necessity's count<=1.
-- if enough necessities are added back, trigger a deletion of reminder.

-- only 1 Soup Cream (inventory_id = 50) left
-- Verify that a reminder for necessity is added
UPDATE inventory
SET count = 1
WHERE inventory_id = 50;

SELECT * FROM reminder;

-- 11 Soup Cream (inventory_id = 50) are stored to the fridge
UPDATE inventory
SET count = 12
WHERE inventory_id = 50;

SELECT * FROM reminder;


-- Expiration Alert

-- 11
-- Geordie(user_id: 15,fridge_id:5) and Kissiah(user_id: 5,fridge_id:2) 
-- want to have Expiration Alerts displayed on their fridge.
-- Order the inventory items from the newest expired to the fartherest.
-- Return an error message if he has not subscribed the iFridge services yet.
-- Notice that we are provided with their fridge IDs.

-- this user has subscribed.
SELECT * FROM reminder;
CALL expirationAlert(2);
SELECT * FROM reminder;
-- this subscribed user decides to go take a closer look at the inventory list.
CALL orderByExpirationDate(5);



-- customize a reminder
-- iFridge is able to customize a reminder and send to everyone in your family!
-- we design this procedure specifically to make the family bond tighter,
-- so everyone in the house is responsible for doing housework, reminding each other, etc.

-- 12
-- The Milazzo's wants to remind grandpa Bordy of injecting his insulin before dinner.
-- Use customizeMsg() to send the reminder to all family members.

SELECT * FROM reminder;
SELECT * FROM assigning;
CALL customizeMsg('Bordy', 'Remind Bordy to inject his insulin before dinner!');
SELECT * FROM reminder;

