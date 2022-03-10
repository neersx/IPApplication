using System.Web.Http.Controllers;
using System.Web.Http.ModelBinding;
using Newtonsoft.Json;

namespace Inprotech.Infrastructure.Web
{
    public class JsonQueryBinder : IModelBinder
    {
        public bool BindModel(HttpActionContext actionContext, ModelBindingContext bindingContext)
        {
            var r = bindingContext.ValueProvider.GetValue(bindingContext.ModelName);
            if (r == null)
            {
                return false;
            }

            bindingContext.Model = JsonConvert.DeserializeObject(r.AttemptedValue, bindingContext.ModelType);

            return true;
        }
    }
}