insert into innova_pramos.ventas (idventa,idtipodocumento,idserie,numeroventa,fechaventa,fechavencimiento,
			idsocionegocio,clientefinal,socionegocio,direccion,departamento,giro,nit,rfc,
            idvendedor,gravado,iva,percepcion,totalventa,idsucursal,condicionpago,idcaja,ctrolventa,status) 
	select a.iddocto,b.idtipodocumento,c.idtipodocumento,a.numero,a.fechadocto,a.fechavenci,
			IFNULL(e.idsocionegocio,1),IFNULL(e.clientefinal,0),a.clipro,a.direccion,
            IFNUll(f.nombre,'SANTA ANA'),a.giro,a.nit,a.nrc,IFNULL(g.cod,1),a.gravadodocto,a.ivadocto,a.retperdocto,a.totaldocto,1,a.condipago+1,1,a.ctrolvta,a.status 
		from innova_agils_pramos1.cyvventas a 
			inner join innova_pramos.tipocambio b on a.idtipodocto=b.idtipodocto and b.origen='TPD'
            inner join innova_pramos.tipocambio c on a.idserie=c.idtipodocto and c.origen='SER'
            inner join innova_agils_pramos1.cyvclipro d on a.idclipro=d.idclipro 
            left join innova_pramos.socionegocios e on d.codclipro=e.codsocionegocio
            left join innova_agils_pramos1.siscata f on a.iddepto=f.id and f.origen='DEP'
            left join innova_agils_pramos1.siscata g on a.idagente=g.id and g.origen='VEN'
		where a.fechadocto='2019-06-03' and a.iddocto not in (select idventa from innova_pramos.ventas ) order by a.iddocto
   