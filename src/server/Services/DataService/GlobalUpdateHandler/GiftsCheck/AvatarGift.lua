
return function(targetId, updateType, metadata, DataService)

	local targetProfile = DataService:GetOfflineProfileFromUserId(targetId)
	
	if targetProfile == nil then
		return false, "Player doesn't have a profile on that game"
	end
	
	local targetHasAvatar = targetProfile.Data.Characters[metadata.avatarId] ~= nil
	local targetHasSameGiftToReceive = false

	for index, update in targetProfile.GlobalUpdates:GetActiveUpdates() do
		if update[2].updateType == 'AvatarGift' then
			if update[2].metadata.avatarId == metadata.avatarId then
				targetHasSameGiftToReceive = true
			end
		end
	end

	for index, update in targetProfile.GlobalUpdates:GetLockedUpdates() do
		if update[2].updateType == 'AvatarGift' then
			if update[2].metadata.avatarId == metadata.avatarId then
				targetHasSameGiftToReceive = true
			end
		end
	end
	
	if targetHasAvatar then
		return false, 'Player already have the avatar'
	end
	
	if targetHasSameGiftToReceive then
		return false, 'Player already have this gift to open'
	end
	
	return true, 'Sending'
	
end