import org.moqui.entity.EntityValue

def ec = context.ec

EntityValue party = ec.entity.makeValue("com.party.Party")
if (!party.partyId) {
    party.setSequencedIdPrimary()
}
party.setFields(context, true, null, null)
party.create()
return [partyId : party.partyId]
