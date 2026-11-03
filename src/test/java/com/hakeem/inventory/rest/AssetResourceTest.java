package com.hakeem.inventory.rest;

import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.hakeem.inventory.model.Asset;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AssetResourceTest {

    @Mock
    private EntityManager em;

    @InjectMocks
    private AssetResource resource;

    @Test
    void createIgnoresIdSentByClient() {
        Asset asset = new Asset();
        asset.setId(999L);
        asset.setAssetTag("LAPTOP-99");

        resource.create(asset);

        assertNull(asset.getId());
        verify(em).persist(asset);
    }

    @Test
    void deleteRemovesExistingAsset() {
        Asset asset = new Asset();
        when(em.find(Asset.class, 7L)).thenReturn(asset);

        resource.delete(7L);
        
        verify(em).remove(asset);
    }
}

