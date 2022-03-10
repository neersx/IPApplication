using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components
{
    public class Component : IComponent
    {
        public Dictionary<string, int> Components { get; private set; }

        public void Load(IDbContext context)
        {
            Components = context.Set<InprotechKaizen.Model.Configuration.Component>()
                                .Select(_ => new
                                {
                                    _.Id,
                                    _.InternalName
                                }).ToDictionary(k => k.InternalName, v => v.Id, StringComparer.InvariantCultureIgnoreCase);
        }
    }
}