using System;
using System.Data;
using Inprotech.Integration.SchemaMapping.Data;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    interface ILocalContext
    {
        object GetDocItemValue(DocItemBinding binding);
    }

    class LocalContext : ILocalContext
    {
        readonly ILocalContext _parent;
        readonly string _nodeId;
        readonly DataRow _docItemValue;

        public LocalContext(ILocalContext parent, string nodeId, DataRow docItemValue)
        {
            _parent = parent;
            _nodeId = nodeId;
            _docItemValue = docItemValue;
        }

        public object GetDocItemValue(DocItemBinding binding)
        {
            if (binding == null)
                return null;

            if (binding.NodeId == _nodeId)
            {
                try
                {
                    var value = _docItemValue[binding.ColumnId];

                    return value == DBNull.Value ? null : value;
                }
                catch (Exception ex)
                {
                    throw XmlGenExceptionHelper.ReadDocItemColumnFailed(binding, _docItemValue, ex);
                }
            }
            if (_parent == null)
                throw XmlGenExceptionHelper.DocItemBoundNodeNotFound(binding);

            return _parent.GetDocItemValue(binding);
        }
    }
}