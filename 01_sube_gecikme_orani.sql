select s.SubeAdi,s.SubeID , count(*) as ToplamGonderi,
sum(case when Teslim.TeslimatSonucu IN ('Gecikmis','Gec')  then 1 
else 0 end) as gecikmeSayisi, 
cast (sum(case when Teslim.TeslimatSonucu IN ('Gecikmis','Gec')  then 1 
else 0 end)*100.0/count(*) as decimal(5,2)) as Gecikmeorani

from dbo.Teslimatlar as teslim
inner join Gonderiler as g
on teslim.GonderiID = g.GonderiID
inner join Subeler as s
on s.SubeID = g.CikisSubeID
group by s.SubeID,s.SubeAdi
order by Gecikmeorani desc
