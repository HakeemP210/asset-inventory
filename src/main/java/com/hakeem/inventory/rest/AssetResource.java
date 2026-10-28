package com.hakeem.inventory.rest;

import com.hakeem.inventory.model.Asset;
import jakarta.enterprise.context.RequestScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.PathParam;
import java.util.List;

@Path("/assets")
@RequestScoped 
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AssetResource {

    @PersistenceContext
    private EntityManager em;

    @GET
    public List<Asset> listAll() {
        return em.createQuery("SELECT a FROM Asset a ORDER BY a.assetTag", Asset.class).getResultList();
    }
    
    @POST
    @Transactional
    public Asset create(Asset asset) {
        asset.setId(null);
        em.persist(asset);
        return asset;
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public void delete(@PathParam("id") Long id) {
        Asset asset = em.find(Asset.class, id);
        if (asset == null) {
            throw new NotFoundException("Asset not found");
        }
        em.remove(asset);
    }
}

