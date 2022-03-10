using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;

namespace InprotechKaizen.Model.Components.Configuration
{
    public class ComponentResolver : IComponentResolver
    {
        readonly IComponent _component;

        public ComponentResolver(IComponent component)
        {
            _component = component;
        }

        public int? Resolve(string componentName)
        {
            if (string.IsNullOrEmpty(componentName)) return null;

            return _component.Components.TryGetValue(componentName, out int componentId)
                ? (int?)componentId
                : null;
        }
    }
}
