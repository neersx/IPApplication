using System;
using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Metadata;

namespace Inprotech.Web.Configuration.Ede.DataMapping.Mappings
{
    public interface IMappingHandlerResolver
    {
        IMappingHandler Resolve(int structureId);
    }

    public class MappingHandlerResolver : IMappingHandlerResolver
    {
        readonly IEnumerable<Meta<Func<IMappingHandler>>> _mappingHandlers;
        public MappingHandlerResolver(IEnumerable<Meta<Func<IMappingHandler>>> mappingHandlers)
        {
            if (mappingHandlers == null) throw new ArgumentNullException("mappingHandlers");
            _mappingHandlers = mappingHandlers;
        }

        public IMappingHandler Resolve(int structureId)
        {
            var m = _mappingHandlers
                .SingleOrDefault(_ => (int)_.Metadata[MappingModule.MapStructureId] == structureId);

            if (m == null)
                throw new NotSupportedException("No mapping handler available for structure: " + structureId);
            
            return m.Value();
        }
    }
}
