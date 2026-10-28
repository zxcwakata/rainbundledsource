local SelfFire = {
	active = false
}

function SelfFire.wrap(fn, ...)
	local old = SelfFire.active
	SelfFire.active = true
	local ok, res = pcall(fn, ...)
	SelfFire.active = old
	if not ok then
		error(res, 0)
	end
	return res
end

return SelfFire
