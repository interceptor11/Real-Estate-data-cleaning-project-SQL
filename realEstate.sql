create database realEstate;
use realEstate;

-- ---------------------------------------------------------- --

/*
Cleaning data in SQL
*/

alter table `nashville housing data for data cleaning`rename nashvillehousing;
select * from nashvillehousing;
set sql_safe_updates = 0;

-- ------------------------------------------------------------------- --

-- Standardise date format
-- data type of sale date is text and having format 'April 9, 2013'

select saledate
from nashvillehousing;

alter table nashvillehousing
add newsaledate text;

SELECT REPLACE(saledate, ',', '')
FROM nashvillehousing;

update nashvillehousing
set newsaledate = REPLACE(saledate, ',', '');

select str_to_date(newsaledate,'%M %e %Y')       -- between quotes put date format as exactly as in database column
from nashvillehousing;

update nashvillehousing
set newsaledate = str_to_date(newsaledate,'%M %e %Y');

-- ----------------------------------------------------------------------- ---

-- populate property address data where there is NULL
-- after examining data, we find out that one parcel id has unique property address
-- so using self join we are going to see how many property address has null value 
-- and same parcel id

UPDATE nashvillehousing SET PropertyAddress = NULL WHERE PropertyAddress = '';

select PropertyAddress
from nashvillehousing
where PropertyAddress is null;

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, ifnull(a.PropertyAddress,b.PropertyAddress)
from nashvillehousing a
join nashvillehousing b
on a.ParcelID=b.ParcelID and a.uniqueid!= b.uniqueid
where a.PropertyAddress is null;


update nashvillehousing a
join nashvillehousing b
on a.ParcelID=b.ParcelID and a.uniqueid!= b.uniqueid
set a.PropertyAddress = ifnull(a.PropertyAddress,b.PropertyAddress)
where a.PropertyAddress is null;

-- --------------------------------------------------------------------------------------------------- --
-- Breaking out address into individual columns (address,city,state)

select
substring(PropertyAddress,1,position(',' in PropertyAddress)-1) as address
, substring(PropertyAddress,position(',' in PropertyAddress)+1,length(PropertyAddress)) as address
from nashvillehousing;

alter table nashvillehousing
add propertySplitAddress varchar(255);

update nashvillehousing
set propertySplitAddress = substring(PropertyAddress,1,position(',' in PropertyAddress)-1);

alter table nashvillehousing
add propertySplitCity varchar(255);

update nashvillehousing
set propertySplitCity = substring(PropertyAddress,position(',' in PropertyAddress)+1,length(PropertyAddress));

-- Breaking out owner into individual columns (address,city,state)  second altenative method other than substring and position

select 
substring_index(owneraddress,',',1),
substring_index(substring_index(owneraddress,',',2),',',-1),
substring_index(owneraddress,',',-1)
from nashvillehousing;

alter table nashvillehousing
add ownerSplitAddress varchar(255);

update nashvillehousing
set ownerSplitAddress = substring_index(owneraddress,',',1);

alter table nashvillehousing
add ownerSplitCity varchar(255);

update nashvillehousing
set ownerSplitCity = substring_index(substring_index(owneraddress,',',2),',',-1);

alter table nashvillehousing
add ownerSplitState varchar(255);

update nashvillehousing
set ownerSplitState = substring_index(owneraddress,',',-1);

 
-- change Y and N to Yes and No in 'sold as vacant' field

select distinct  soldasvacant , count(soldasvacant)
from nashvillehousing
group by soldasvacant
;

select soldasvacant,
case 
when soldasvacant='Y' then 'Yes' 
when soldasvacant='N' then 'No' 
else soldasvacant
end as newsoldasvacant
from nashvillehousing;

update nashvillehousing 
 set soldasvacant = case 
when soldasvacant='Y' then 'Yes' 
when soldasvacant='N' then 'No' 
else soldasvacant
end;

-- -------------------------------------------------------------------- --

-- Remove duplicates
-- when ranking duplicates comes with rank 2
with rownumCTE as (

select *,
	row_number() over (
    partition by parcelid,
				propertyaddress,
                saleprice,
                saledate,
                legalreference
                order by
                uniqueid
    ) row_num
    
from nashvillehousing
order by ParcelID
)

select *
from rownumCTE
where row_num>1;



with rownumCTE as (

select *,
	row_number() over (
    partition by parcelid,
				propertyaddress,
                saleprice,
                saledate,
                legalreference
                order by
                uniqueid
    ) row_num
    
from nashvillehousing
order by ParcelID
)

delete
from rownumCTE
where row_num>1;



 
