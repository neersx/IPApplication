using System;

namespace Inprotech.Infrastructure.ResponseEnrichment
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
    public class NoEnrichmentAttribute : Attribute
    {
    }
}
