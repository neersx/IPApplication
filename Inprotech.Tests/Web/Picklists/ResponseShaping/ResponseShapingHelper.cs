using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Reflection;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Inprotech.Web.Picklists.ResponseShaping;

namespace Inprotech.Tests.Web.Picklists.ResponseShaping
{
    public static class TestHelper
    {
        public static HttpActionExecutedContext CreateActionExecutedContext(
            object payload, MethodInfo methodInfo, string uri = "/api/picklists/somepicklist")
        {
            var actionDescriptor = new ReflectedHttpActionDescriptor(
                                                                     new HttpControllerDescriptor(), methodInfo);

            var controllerContext = new HttpControllerContext
            {
                Request =
                    new HttpRequestMessage(HttpMethod.Get,
                                           new Uri(new Uri("http://myorg/cpainpro/i"), uri))
            };

            var actionContext = new HttpActionContext(controllerContext, actionDescriptor)
            {
                Response = new HttpResponseMessage
                {
                    Content =
                        new ObjectContent(payload.GetType(), payload,
                                          new JsonMediaTypeFormatter())
                }
            };

            return new HttpActionExecutedContext(actionContext, null);
        }
    }

    public static class ColumnsExtensions
    {
        public static IEnumerable<string> DisplayableFields(this Type type)
        {
            foreach (var property in type.GetProperties().OrderBy(x => x.MetadataToken))
            {
                var attribute = property.GetCustomAttribute<PicklistDescriptionAttribute>() ?? property.GetCustomAttribute<DisplayNameAttribute>();
                if (attribute == null) continue;

                yield return property.Name;
            }
        }

        public static IEnumerable<string> SortableFields(this Type type)
        {
            foreach (var property in type.GetProperties().OrderBy(x => x.MetadataToken))
            {
                var attribute = property.GetCustomAttribute<PicklistColumnAttribute>();
                if (attribute == null) continue;

                if (!attribute.Sortable) continue;

                yield return property.Name;
            }
        }

        public static IEnumerable<string> HighlightedFields(this Type type)
        {
            foreach (var property in type.GetProperties().OrderBy(x => x.MetadataToken))
            {
                var attribute = property.GetCustomAttribute<PicklistColumnAttribute>();
                if (attribute == null) continue;

                yield return property.Name;
            }
        }

        public static IEnumerable<string> TogglableFields(this Type type)
        {
            foreach (var property in type.GetProperties().OrderBy(x => x.MetadataToken))
            {
                var attribute = property.GetCustomAttribute<PicklistColumnAttribute>();
                if (attribute == null) continue;

                if (!attribute.Menu) continue;

                yield return property.Name;
            }
        }
    }
}