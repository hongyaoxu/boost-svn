//-----------------------------------------------------------------------------
// boost mpl/push_front.hpp header file
// See http://www.boost.org for updates, documentation, and revision history.
//-----------------------------------------------------------------------------
//
// Copyright (c) 2000-02
// Aleksey Gurtovoy
//
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_MPL_PUSH_FRONT_HPP_INCLUDED
#define BOOST_MPL_PUSH_FRONT_HPP_INCLUDED

#include "boost/mpl/push_front_fwd.hpp"
#include "boost/mpl/aux_/push_front_impl.hpp"
#include "boost/mpl/aux_/sequence_tag.hpp"
#include "boost/mpl/aux_/void_spec.hpp"
#include "boost/mpl/aux_/lambda_support.hpp"

namespace boost {
namespace mpl {

template<
      typename BOOST_MPL_AUX_VOID_SPEC_PARAM(Sequence)
    , typename BOOST_MPL_AUX_VOID_SPEC_PARAM(T)
    >
struct push_front
    : push_front_traits< typename BOOST_MPL_AUX_SEQUENCE_TAG(Sequence) >
        ::template algorithm< Sequence,T >
{
    BOOST_MPL_AUX_LAMBDA_SUPPORT(2,push_front,(Sequence,T))
};

BOOST_MPL_AUX_VOID_SPEC(2, push_front)

} // namespace mpl
} // namespace boost

#endif // BOOST_MPL_PUSH_FRONT_HPP_INCLUDED
