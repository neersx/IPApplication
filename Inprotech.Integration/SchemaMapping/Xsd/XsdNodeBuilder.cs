using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.Xsd.Data;
using Attribute = Inprotech.Integration.SchemaMapping.Xsd.Data.Attribute;

namespace Inprotech.Integration.SchemaMapping.Xsd
{
    class XsdNodeBuilder : IXsdObjectVisitor
    {
        readonly Stack<XsdNode> _stack = new Stack<XsdNode>();
        readonly Stack<XsdNode> _parentStack = new Stack<XsdNode>();

        public void Visit(XmlSchemaObject obj)
        {
            var result = Build(obj);

            if (result != null)
                _stack.Push(result);
        }

        public void BeginChildren()
        {
            _parentStack.Push(_stack.Peek());
        }

        public void EndChildren()
        {
            var parent = _parentStack.Pop();
            var children = new List<XsdNode>();

            while (_stack.Peek() != parent)
            {
                var child = _stack.Pop();
                child.Parent = parent;
                children.Insert(0, child);
            }

            _stack.Peek().Children = children;
        }

        public bool IsCircular(XmlSchemaObject obj)
        {
            var result = Build(obj);

            return _parentStack.Any(_ => _.Name == result.Name && _.NodeType == result.NodeType && _.Line == result.Line && _.Column == result.Column);

        }

        public XsdNode GetResult()
        {
            if (_stack.Count != 1)
                throw new Exception("There must be only one item on the stack.");

            return _stack.Pop();
        }

        XsdNode Build(XmlSchemaObject obj)
        {
            return Build(obj as XmlSchemaChoice) ??
                   Build(obj as XmlSchemaElement) ??
                   Build(obj as XmlSchemaAttribute) ??
                   Build(obj as XmlSchemaSequence);
        }

        XsdNode Build(XmlSchemaElement element)
        {
            if (element == null) return null;

            return new Element(element);
        }

        XsdNode Build(XmlSchemaAttribute attribute)
        {
            if (attribute == null) return null;

            return new Attribute(attribute);
        }

        XsdNode Build(XmlSchemaChoice choice)
        {
            if (choice == null) return null;

            return new Choice(choice);
        }

        XsdNode Build(XmlSchemaSequence sequence)
        {
            if (sequence == null) return null;

            return new Sequence(sequence);
        }
    }
}