local storage_service = identifyexecutor() == "Synapse Z" and services.MemStorageService or services.MemStorageService;

if identifyexecutor() == "Synapse Z" then
    local existing_data = storage_service:GetItem("persistent_data");
    if not existing_data or #existing_data <= 0 then
        storage_service:SetItem("persistent_data", "{}");
    end
elseif not storage_service:HasItem("persistent_data") then
    storage_service:SetItem("persistent_data", "{}");
end

local persistent_data = {} do
    persistent_data.__index = persistent_data;
    persistent_data.current = storage_service:GetItem("persistent_data") or "{}";

    function persistent_data:wipe()
        self.current = "{}";
        storage_service:SetItem("persistent_data", self.current);
    end

    function persistent_data:set(key, value)
        local decoded = services.HttpService:JSONDecode(self.current);
        decoded[key] = value;
        
        self.current = services.HttpService:JSONEncode(decoded);
        storage_service:SetItem("persistent_data", self.current);
    end;

    function persistent_data:remove(key)
        local decoded = services.HttpService:JSONDecode(self.current);
        decoded[key] = nil;
        self.current = services.HttpService:JSONEncode(decoded);
        storage_service:SetItem("persistent_data", self.current);
    end;

    function persistent_data:get(key, or_default)
        return services.HttpService:JSONDecode(self.current)[key] or or_default    
end;
end;
    -- restore: stf отсутствовал, а портируемая автоматизация Luma
    -- (AutomationStruct и фармы) вызывает его постоянно. Семантика
    -- из Luma Utility/PersistentData.lua: записать key внутрь табличного
    -- поля field и сохранить. Пустая таблица тоже допустима.
    function persistent_data:stf(field, key, value)
        local tbl = self:get(field);
        if type(tbl) ~= "table" then
            tbl = {};
        end;
        tbl[key] = value;
        self:set(field, tbl);
        return value;
    end;

    return persistent_data
