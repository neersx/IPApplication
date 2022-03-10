using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Names
{
    public static class NameCharacteristics
    {
        public const short Organisation = 0;
        public const short Individual = 1;
        public const short Staff = 2;
        public const short Client = 4;

        public static short[] AllowableUsage(
            bool includeIndividuals,
            bool includeOrganisations,
            bool includeStaffMembers,
            bool includeClients)
        {
            var inclusions = new HashSet<short>();

            if(includeClients)
            {
                if(includeIndividuals) inclusions.Add(Client | Individual);
                if(includeOrganisations) inclusions.Add(Client | Organisation);
            }
            else
            {
                if(includeIndividuals)
                {
                    inclusions.Add(Individual);
                    inclusions.Add(Individual | Client);
                }
                if(includeOrganisations)
                {
                    inclusions.Add(Organisation);
                    inclusions.Add(Organisation | Client);
                }
                if(includeStaffMembers)
                {
                    inclusions.Add(Staff);
                    inclusions.Add(Staff | Individual);
                }
            }

            return inclusions.ToArray();
        }
    }
}