// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

function quickSort(uint[] memory arr,int _left,int _right) pure{
    int i = _left;
    int j = _right;
    if(i == j) {
        return;
    }
    uint pivot = arr[uint(_left + (_right -_left)/2)];
    while(i <= j){
        while(arr[uint(i)] < pivot){
            i++;
        }
        while(pivot < arr[uint(j)]){
            j--;
        }
        if(i <= j){
            (arr[uint(i)],arr[uint(j)]) = (arr[uint(j)],arr[uint(i)]);
            i++;
            j--;
        }
    }
    if(_left < j){
        quickSort(arr,_left,j);
    }
    if(i<_right){
        quickSort(arr,i,_right);
    }
}

contract QuickSort {
    function sort(uint[] memory data) public pure returns (uint[] memory){
        quickSort(data,int(0),int(data.length - 1));
        return data;
    }
}