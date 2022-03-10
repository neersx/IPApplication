using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Xml.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Documents;
using Inprotech.Integration.ExternalApplications.Crm;
using Inprotech.Tests.Server;
using Inprotech.Web.Accounting.Billing;
using Inprotech.Web.Policing;
using Inprotech.Web.PriorArt;
using Inprotech.Web.PriorArt.Maintenance.Attachments;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class CaseAuthorizationFilterScenarioFacts
    {
        [Fact]
        public void ShouldExistsOnCaseRelatedApiControllers()
        {
            var exclusions = new Dictionary<MethodInfo, string>
            {
                { typeof(CrmController).GetMethod(nameof(CrmController.UpdateResponse)), "ApiKey logic enclosed, needs further review" },
                { typeof(CrmController).GetMethod(nameof(CrmController.UpdateCorrespondence)), "ApiKey logic enclosed, needs further review" },
                { typeof(CrmController).GetMethod(nameof(CrmController.ListContacts)), "ApiKey logic enclosed, needs further review" },
                { typeof(CrmController).GetMethod(nameof(CrmController.RemoveContact)), "ApiKey logic enclosed, needs further review" },
                { typeof(CrmController).GetMethod(nameof(CrmController.AddContact)), "ApiKey logic enclosed, needs further review" },
                { typeof(CrmController).GetMethod(nameof(CrmController.CreateNewContact)), "ApiKey logic enclosed, needs further review" },
                { typeof(CrmController).GetMethod(nameof(CrmController.AddContactActivity)), "ApiKey logic enclosed, needs further review" },
                { typeof(DocumentsController).GetMethod(nameof(DocumentsController.Get)), "logic enclosed within controller" },
                { typeof(PolicingQueueController).GetMethod(nameof(PolicingQueueController.GetErrorsFor)), "Administrative functions do not have case authorizations" },
                { typeof(PriorArtEvidenceSearchController).GetMethod(nameof(PriorArtEvidenceSearchController.Index)), "logic enclosed within controller" },
                { typeof(AttachmentsMaintenanceController).GetMethod(nameof(AttachmentsMaintenanceController.View)), "logic enclosed within controller" }
            };

            foreach (var c in AllRegisteredControllers.Get())
            {
                foreach (var m in c.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.DeclaredOnly).Except(exclusions.Keys))
                {
                    var attr = m.GetCustomAttribute<RequiresCaseAuthorizationAttribute>();
                    if (attr != null) continue;

                    var warnings = new List<string>();

                    foreach (var parameter in m.GetParameters())
                    {
                        if (!parameter.ParameterType.IsComplexType())
                        {
                            if (RequiresCaseAuthorizationAttribute.CommonPropertyNames.Contains(parameter.Name))
                            {
                                warnings.Add($"   {parameter.Name}");
                            }

                            continue;
                        }

                        if (parameter.ParameterType.IsXml())
                        {
                            // not supported, stackoverflow risk
                            continue;
                        }

                        TraverseDown(parameter.ParameterType, parameter.Name, warnings);
                    }

                    Assert.False(warnings.Any(), $"Should {c}.{m.Name} have a RequiresCaseAuthorizationAttribute?{Environment.NewLine}{string.Join(Environment.NewLine, warnings)}");
                }
            }

            void TraverseDown(Type thisLevel, string path, List<string> all)
            {
                var properties = thisLevel.GetProperties(BindingFlags.Instance | BindingFlags.Public);
                foreach (var property in properties)
                {
                    if (property.PropertyType.IsArray || property.PropertyType.IsEnumerableOfT())
                    {
                        // Enumerable or array type not yet supported.
                        continue;
                    }

                    var thisPath = $"{path}.{property.Name}";

                    // stackoverflow may occur
                    var stackOverflowGuard = thisPath.Split('.');
                    if (stackOverflowGuard.Length - stackOverflowGuard.Distinct().Count() > 3)
                    {
                        continue;
                    }

                    if (!property.PropertyType.IsComplexType())
                    {
                        if (RequiresCaseAuthorizationAttribute.CommonPropertyNames.Contains(property.Name))
                        {
                            all.Add($"   {thisPath}");
                        }

                        continue;
                    }

                    TraverseDown(property.PropertyType, thisPath, all);
                }
            }
        }

        [Fact]
        public void ShouldReferToCorrectParameters()
        {
            foreach (var c in AllRegisteredControllers.Get())
            {
                foreach (var m in c.GetMethods(BindingFlags.Instance | BindingFlags.Public))
                {
                    var attr = m.GetCustomAttribute<RequiresCaseAuthorizationAttribute>();
                    if (attr == null) continue;

                    Assert.False(attr.HasPropertyName() && attr.HasPropertyPath(), $"controller {c}, action {m.Name} has invalid RequiresCaseAuthorization configuration.");

                    var allPropertyNames = m.GetParameters().Select(_ => _.Name);
                    if (attr.IsDefault())
                    {
                        Assert.True(allPropertyNames.Any(_ => RequiresCaseAuthorizationAttribute.CommonPropertyNames.Contains(_)),
                                    $"controller {c}, action {m.Name} does not have any of '{string.Join(",", RequiresCaseAuthorizationAttribute.CommonPropertyNames)}'.");
                    }
                    else if (attr.HasPropertyName())
                    {
                        Assert.True(allPropertyNames.Contains(attr.PropertyName),
                                    $"controller {c}, action {m.Name} does not have the property {attr.PropertyName}.");
                    }
                    else
                    {
                        Assert.True(attr.PropertyPath.Contains("."), $"controller {c}, action {m.Name} has invalid RequiresCaseAuthorization configuration.");

                        var propertyQueue = new Queue<string>(attr.PropertyPath.Split('.'));
                        var topLevelArg = propertyQueue.Dequeue();

                        Assert.True(allPropertyNames.Contains(topLevelArg), $"controller {c}, action {m.Name} does not have property {topLevelArg}.");

                        var currentParameterInfo = m.GetParameters().First(_ => _.Name == topLevelArg);
                        var type = currentParameterInfo.ParameterType;
                        var current = $"{topLevelArg}";
                        while (propertyQueue.Any())
                        {
                            var propertyName = propertyQueue.Dequeue();
                            current += $".{propertyName}";

                            var property = type.GetProperty(propertyName);

                            Assert.True(property?.Name == propertyName, $"controller {c}, action {m.Name} does not have property path {current}");
                            type = property.PropertyType;
                        }
                    }
                }
            }
        }
    }
    
    public static class RequireCaseAuthorizationAttributeExtension
    {
        public static bool IsDefault(this RequiresCaseAuthorizationAttribute attribute)
        {
            return !attribute.HasPropertyName() && string.IsNullOrWhiteSpace(attribute.PropertyPath);
        }

        public static bool HasPropertyName(this RequiresCaseAuthorizationAttribute attribute)
        {
            return !string.IsNullOrWhiteSpace(attribute.PropertyName);
        }

        public static bool HasPropertyPath(this RequiresCaseAuthorizationAttribute attribute)
        {
            return !string.IsNullOrWhiteSpace(attribute.PropertyPath);
        }
    }

    public static class TypeProberExtensions
    {
        public static bool Implements(this Type type, Type contract)
        {
            return contract.IsGenericTypeDefinition
                ? type.GetInterfaces().Any(i => i.IsGenericType && i.GetGenericTypeDefinition().Equals(contract))
                : type.GetInterfaces().Any(i => i.Equals(contract));
        }

        public static bool IsEnumerableOfT(this Type type)
        {
            return type.Implements(typeof(IEnumerable<>));
        }

        public static bool IsComplexType(this Type type)
        {
            return !(type.IsPrimitive || type.IsValueType || type == typeof(string));
        }

        public static bool IsXml(this Type type)
        {
            return type == typeof(XElement) || type == typeof(XDocument);
        }
    }
}